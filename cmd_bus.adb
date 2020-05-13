--------------------------------------------------------
--包   名：cmd_switch
--功能描述：本包定义指令路由
--对外接口：
--创建日期：2015-03-18
--版权所有：上海卫星工程研究所--十六室--软件组
--------------------------------------------------------
with data_check; use data_check;
--  with time_mgmt; use time_mgmt;
with rs422_srv ; use rs422_srv;
with B1553_Srv_Module; use B1553_Srv_Module;
with bsp.tmtc; use bsp.tmtc;

package body cmd_bus is

   --延时队列返回空指令元素
   function nulqueueCmd return QueCmd_type is
      ReturnCmd   :  QueCmd_type;
   begin
      ReturnCmd.time       := 0;
      ReturnCmd.Cmd_pak.Head.apid   := 0;
      return ReturnCmd;
   end;

   --立即队列返回Apid为767的空指令
   function NulCmd return Comm_pkg_type is
      ReturnCmd   :  Comm_pkg_type;
   begin
      --ReturnCmd.Head.apid  := Err_Apid;
      ReturnCmd.Head.apid  := 0;
      ReturnCmd.Head.len   := 0;
      return ReturnCmd;
   end;

   --422队列返回空带参指令/固存指令
   function NulCmdHstry return Cmd_hstry_type is
      CmdHstry :  Cmd_hstry_type;
   begin
      CmdHstry.CmdT					:= 0;
      CmdHstry.CmdApid			:= 0;
      CmdHstry.CmdCode		:= 0;

      return CmdHstry;
   end NulCmdHstry;

   function GE (P, Q : in QueCmd_type) return Boolean is
   begin
      return (P.Time >= Q.Time);
   end GE;

   function EQ (P, Q : in QueCmd_type) return Boolean is
   begin
      return (P.Time = Q.Time);
   end EQ;

begin
   CmdFlush;
end cmd_bus;

