`timescale 1ns / 1ps

//需要将vga.v里的两个延时计数改为d5
 module testbench; //声明testbench名称
  reg CLK;
  reg RSTn; //信号声明
  reg [4:0] button;
  reg [15:0] sw;
  wire v;
  wire h;
  wire [11:0]rgb;
  wire [15:0]LED;
  //下面的shift_reg设计的实例化
top dut(
.CLK (CLK), 
.RSTn (RSTn), 
.button (button),
.sw (sw),
.v(v),
.h(h),
.rgb(rgb),
.LED(LED));

   //此进程块设置自由运行时钟
  initial begin
  CLK = 0;
  forever #1 CLK = ~CLK;
  end
  initial begin//此过程块指定刺激。
    RSTn = 0;
    button = 5'b00000;
    sw = 16'b0000000000000000;
   #200
    RSTn = 1;
    sw = 16'b0000000000000001;
   #200
    sw = 16'b0000000000000000;
   #200
    button = 5'b00001;//右
   #200
    button = 5'b00000;
   #200
    button = 5'b00100;//中
   #200
    button = 5'b00000;
   #200
    button = 5'b01000;//下
   #200
   button = 5'b00000;
   #200
   button = 5'b01000;//下
   #200
   button = 5'b00000;
   #200
   sw = 16'b0000000000000010;
   #200
   sw = 16'b0000000000000000;
   #200
   button = 5'b00100;//中1
   #200
   button = 5'b00000;
   #200
   button = 5'b00100;//中2
   #200
   button = 5'b00000;
   #200
   button = 5'b00100;//中3
   #200
   button = 5'b00000;
   #200
   button = 5'b00100;//中4
   #200
   button = 5'b00000;
   #1000 $stop;
  end
 endmodule
