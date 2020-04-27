-----------------------------------------------------------------------
--包   名： 标准输入输出包
--版本号：   ver.1.0.0
--创建日期： 2015.09.15
--修改memcpy等汇编代码，使用编译器指定寄存器

-----------------------------------------------------------------------
with interfaces; use interfaces;
with machine_code; use machine_code;
with system; use system;


package Bsp.stdio is

   procedure Init;
   function xi ( Addr : Address) return CPU_Type;
   pragma inline (xi);
   procedure xo (Data : CPU_Type; Addr : Address);
   pragma inline (xo);

   --字符输出函数、标准输出
   procedure Put ( C : Character);
   procedure Put ( C : Unsigned_8);
   procedure Put ( C : Unsigned_16);
   procedure Put ( C : Unsigned_32);
   procedure Put ( C : Unsigned_64);
   procedure Put ( C : Integer);
   procedure Put ( C : Address);
   procedure Put ( C : Address; Len:Unsigned_32);
   procedure Put ( S : String);
   procedure Put_Line ( S : String);
   procedure New_line;

   function  get return Character;

   -- 存储器拷贝
   -- 8位拷贝 长度1代表为1个8位数
   procedure memcpy (Dst : address; Src : Address; Len : CPU_Type);
   --16位拷贝 长度1代表1个16位数
   procedure memcpy16 (Dst : address; Src : Address; HfLen : CPU_Type);
   --32位拷贝 长度1代表1个32位数
   procedure memcpy32 (Dst : address; Src : Address; WLen : CPU_Type);
   --32位设置 长度1代表1个32位数，数据为32位
   procedure memset (Dst : address; Len : CPU_Type; Data : CPU_Type);
   -- IO区域读取 源地址位为16位，目的地址为32位，长度1表示读一个16位数
   procedure IO_Read (Dst : Address; Src : Address; Len : CPU_Type);
   -- IO区域输出 源地址位为32位，目的地址为16位，长度1表示写一个16位数
   procedure IO_Write (Dst : Address; Src : Address; Len : CPU_Type);

private
   --寄存器
   STAT_Reg : constant := 16#01F8_00E8#;
   DATA_Reg : constant := 16#01F8_00E0#;
   --状态掩码
   TXRDY_MASK    : constant := 16#0004#;
   RXRDY_MASK    : constant := 16#0001#;
   RXERR_MASK    : constant := 16#0070#;
   RXCLR_MASK    : constant := 16#0000#;

   Hexchars : constant array (0 .. 15) of Character :=
                ('0', '1', '2', '3', '4', '5', '6', '7',
                '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
   Percent  : constant array (0 .. 9) of CPU_Type :=
     (10_0000_0000 , 1_0000_0000 , 1000_0000 , 100_0000 , 10_0000, 10000, 1000, 100, 10, 1);
  function CtoU (C : Character) return Unsigned_8;
  pragma inline (CtoU);
  function UtoC (U : Unsigned_8) return Character;
  pragma inline (UtoC);

end Bsp.stdio;