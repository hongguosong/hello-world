--------------------------------------------------------
--包   名：cmd_switch
--功能描述：本包定义指令路由
--对外接口：
--创建日期：2015-03-18
--版权所有：上海卫星工程研究所--十六室--软件组
--------------------------------------------------------
with System;  use System;
with Interfaces; use Interfaces;
with bsp;  use bsp;
with bsp.stdio;   use bsp.stdio;
with type_def;use type_def;
with ccsds_def;use  ccsds_def;
with apid_def; use apid_def;
with tc_pkt_pool; use tc_pkt_pool;
--with debug_lib; use debug_lib;
with queue;
with tm_bus;use tm_bus;
with tm_bus_conf; use tm_bus_conf;
with b1553_srv_conf; use b1553_srv_conf;
with rs422_srv_conf; use rs422_srv_conf;
with bsp.basetime;use bsp.basetime;
with task_conf; use task_conf;
with PriorityQueue;
with Unchecked_Conversion;
with health_mgmt; use health_mgmt;

package cmd_bus is
   --数据包校验结果定义
   type Pkt_State_Type is
      record
         Apid_Err    :  boolean;          --1 Apid错误
         Len_Err     :  boolean;          --1 长度错误
         Xor_Err     :  boolean;          --1 校验和错误
         queue_elert    :  boolean;          --1 指令队列深度超过480
         Err_Flag    :  boolean;          --1 包错误(统一表示是否有错误)
         Apid        :  Bit11_Type;       --数据包的Apid
      end record;
   for Pkt_State_Type use
      record
         Apid_Err    at 0 range 0..0;
         Len_Err     at 0 range 1..1;
         Xor_Err     at 0 range 2..2;
         queue_elert    at 0 range 3..3;
         Err_Flag    at 0 range 4..4;
         Apid        at 0 range 5..15;
      end record;
   for Pkt_State_Type'size use 16;

   --指令总线遥测
   type Cmd_tm_type is
      record
         Dly_CmdQueue_Depth      	:  Unsigned_16;      --延时队列深度
         Dly_Data_Num            			:  Unsigned_8;       --注数池深度（可不用下传）
         Dly_Data_Err_Num      			:  Unsigned_8;       --延时数据（内层包）错误计数（可不用下传，用事件方式）
         tc_cnt                  						:  Unsigned_8;       --遥控注数总数
         tc_fail_cnt             						:  Unsigned_8;       --遥控错误计数
         tc_state                						:  Pkt_State_Type;   --遥控包检验结果
         reserved2				          			:  Unsigned_16;      --
         cmd_func                					:  Unsigned_16;      --当前数据包的功能标识
		 	XorValue			     							:  Unsigned_16; 	  --当前数据包Xor
		 	reserved				 							:	unsigned_16;	  --保留
      end record;
   for Cmd_tm_type'Size use 128;
   Cmd_tm_buf        :  Cmd_tm_type;

   type Cmd_hstry_type is
      record
         CmdT			:		unsigned_16;		--时间码4、5两个字节
         CmdApid  :		unsigned_16;
         CmdCode	:		Unsigned_16;		--指令码
      end record;
   for Cmd_hstry_type'size use 48;

--     Cmd_Depth_Alert   :  boolean;                   --指令队列深度预警
--     Cmd_Err_Num       :  unsigned_8;                --指令包错误计数

   -- 获取地面遥控数据,若校验正确则调用routeCmd
   procedure GetTc;

   --判断是否是软件构件的Apid
   function isAppApid(Apid  : bit11_type) return integer ;

   --检查包的合法性(长度/Apid/Xor)
   --PktAddr   ：  包的地址
   --len       ：  包的长度
   --返回检验结果
   function CheckPkt(PktAddr     :  in    Address;
                     len         :  in    Unsigned_16)return Pkt_State_Type;

   --软件构件获取遥控包
   --moudle_Apid  ：  取数构件的Apid
   --ddr          ：  读取数据的存放地址
   --返回获取数据的长度
   function ReadTcData (moudle_Apid    :  Bit11_Type;
                        addr           :  address) return Unsigned_16;

   --根据apid将指令路由到对应链路
   --data_addr：数据起始地址   len：数据长度
   --data_flag: true传送完整包数据    flase传送裸数据
   procedure RouteCmd (data_addr : Address; len : Unsigned_16;
                       data_flag : boolean := true);

   --构件数据包缓存待处理
 	protected AppData is
   procedure AppDataProcess(addr : Address;
                            len  : unsigned_16);
   end AppData;

   --延时指令出队
   procedure Run;

   --延时指令入队
   procedure InsertCmd (  Cmd_Time     :  Unsigned_64;
                        Cmd_pkg     :  comm_pkg_type);

   --延时队列、立即队列清空，同时释放遥控缓冲池空间（发送时注意是否有程控任务执行，会将程控发出的立即指令一同清除）
   procedure CmdFlush;

   function GE (P, Q : in QueCmd_type) return Boolean ;
   function EQ (P, Q : in QueCmd_type) return Boolean ;

   function NulCmd return comm_pkg_type;
   function nulqueueCmd return QueCmd_type;
   function NulCmdHstry return Cmd_hstry_type;

   --延时指令队列
   package Cmd_Queue is new PriorityQueue (Obj => QueCmd_type,
					   ">=" => GE,
					   "="  => EQ,
					   Nul => nulqueueCmd);
   use Cmd_Queue;

   --422立即队列
   package rs422_queue is new Queue (Obj => comm_pkg_type,Nul => NulCmd);
   use rs422_queue;

   --1553立即队列
   package b1553_queue is new Queue (Obj => comm_pkg_type, Nul => NulCmd);
   use b1553_queue;

   package cmd_record_queue is new Queue (Obj => Cmd_hstry_type, Nul => NulCmdHstry);
   use cmd_record_queue;

private
   type APID_FlAG is (APPAPID,APID53,APID42,APIDERR);

   --Apid一发多处理
   type MULT_APID_TYPE is
      record
         num      :     bit5_type;
         Apid     :     bit11_type;
      end record;
   for MULT_APID_TYPE use
      record
         num at 0 range 0..4;
         Apid at 0 range 5..15;
      end record;
   for MULT_APID_TYPE'size use 16;

   --若指令记录队列非空，则每256s取8条组包放入遥测池，由遥测构件放入延遥区
   type Cmd_hstry_array_type	is Array(1..8) of  Cmd_hstry_type;
   for Cmd_hstry_array_type'size use 48 * 8;
   type Cmd_hstry_pkt_type is
      record
         head		: U16array(1..3)	:=(16#40C#,16#C000#,47);
         Items	:	Cmd_hstry_array_type		:= (others=>(16#AAAA#,16#AAAA#,16#AAAA#));
   end record;
	for Cmd_hstry_pkt_type'size use 54 * 8;

   tc_num	: constant 	:= 6;					--默认开辟6个遥控缓存空间
   Tc_data_Array : array (1..tc_num) of TC_Pkt_Type;-- := (others => (others=>0));
   Tc_falg_array : array (1..tc_num) of boolean	 := (others=>false);

   --变量声明
   Real_time   :  unsigned_64;         --实时系统时间，0.1s更新，用于指令出队入队

   cmd_cycle					:	unsigned_16	:= 1;		--指令任务周期计数
   cmd_histry_cycle 	:	constant	:= 2560;			--指令记录存遥测池周期

   headlen     :  constant  := 6;--包头长度
--     Raw_func_id :  Constant := 6;

   --Apid 按去向分类
   function apidClassify(Apid :  bit11_type) return APID_FlAG;

end cmd_bus;