module VGA_sig(
//clk_40M , //输入40M时钟
Reset_n , //复位信号
hsyncb , //行同步信号
vsyncb , //场同步信号
red_0 ,
red_1 ,
red_2 ,
red_3 ,
gree_0 ,
gree_1 ,
gree_2 ,
gree_3 ,
blue_0,
blue_1,
blue_2,
blue_3,
clk_in1
);
 input clk_in1;
wire  clk_40M;
input Reset_n ;
output reg hsyncb ;
output reg vsyncb ;
output red_0 ;
output red_1 ;
output red_2 ;
output red_3 ;
output gree_0 ;
output gree_1 ;
output gree_2 ;
output gree_3 ;
output blue_0;
output blue_1;
output blue_2;
output blue_3;
reg red ;
reg gree ;
reg blue ;
//定义相关常量，参考VGA标准
//时钟频率40M ；
//行同步时间：128像素 ； 行消隐后沿：88像素 ；行消隐前沿 ：40像素 ；
//场同步时间：4行；场消隐后沿：23行 ；场消隐前沿：1行；
parameter H_PIXELS = 800 ; //行显示点数
parameter H_FRONT = 40 ; //行消隐前沿点数
parameter H_BACK = 88 ; //行消隐后沿点数
parameter H_SYNCTIME = 128 ; //行同步点数
parameter H_PERIOD = H_PIXELS + H_FRONT + H_BACK + H_SYNCTIME;
//行周期 1056像素
parameter V_LINES = 600 ; //场显示行数
parameter V_FRONT = 1 ; //场消隐前沿行数
parameter V_BACK = 23 ; //场消隐后沿行数
parameter V_SYNCTIME = 4 ; //场同步行数
parameter V_PERIOD = V_LINES + V_FRONT + V_BACK + V_SYNCTIME;
//场周期 628行
reg [10:0] hcnt ;
reg [9:0] vcnt ;
//产生行计数输出

always@( posedge clk_40M )
	begin
		if( !Reset_n )
			hcnt <= 0 ;
		else if( hcnt < H_PERIOD - 1 )
			hcnt <= hcnt + 1'b1 ;
		else
			hcnt <= 0 ;
	end
//产生场计数输出
always@(posedge clk_40M )
	begin
		if( !Reset_n )
			vcnt <= 0 ;
		else
			begin
				if( hcnt >= H_PERIOD - 1 && vcnt >= V_PERIOD - 1 )
					vcnt <= 0 ;
				else if( hcnt >= H_PERIOD - 1 )
					vcnt <= vcnt + 1'b1 ;
				else
					vcnt <= vcnt ;
			end
	end
//产生行同步信号 ，hsyncb低电平有效
always@( posedge clk_40M )
	begin
		if( !Reset_n )
			hsyncb <= 0 ;
		else
			begin
				if( hcnt < H_SYNCTIME -1 || hcnt == H_PERIOD - 1 )
				//行计数值为0-95之间产生行同步信号，低电平有效
					hsyncb <= 0 ;
				else
					hsyncb <= 1 ;
			end
	end
//产生场同步信号，vsyncb低电平有效
always@( posedge clk_40M )
	begin
		if( !Reset_n )
			vsyncb <= 0 ;
		else
			begin
				if( vcnt <= V_SYNCTIME - 1 )
				//场计数值为0-1时产生场同步信号，低电平有效
					vsyncb <= 0 ;
				else
					vsyncb <= 1 ;
			end
	end
reg enable ;

always@( posedge clk_40M )
	begin
		if( !Reset_n )
			enable <= 0 ;
		else
			begin
				//当行计数或场计数处于控制区时是RGB输出全为零，消隐
				if( hcnt >= (H_SYNCTIME + H_BACK) -1 &&
					hcnt < (H_SYNCTIME + H_BACK + H_PIXELS ) -1 &&
					vcnt >= (V_SYNCTIME + V_BACK) &&
					vcnt <= (V_SYNCTIME + V_BACK + V_LINES ) - 1 )
					enable <= 1 ;
				else
				enable <= 0 ;
			end
	end
//VGA的控制这里就不详细说了，就说明实现显示图片的部分。其核心代码为：
reg [10:0] address_x ;
reg [10:0] address_y ;
always@( posedge clk_40M )
	begin
		if( !Reset_n )
			begin
				address_x <= 0 ;
				address_y <= 0 ;
			end
		else
			begin
				if( hcnt >= (H_SYNCTIME + H_BACK - 1 )&&
				hcnt < (H_SYNCTIME + H_BACK + H_PIXELS ) -1 &&
				vcnt >= (V_SYNCTIME + V_BACK) &&
				vcnt <= (V_SYNCTIME + V_BACK + V_LINES ) - 1 )
					begin
						address_x <= hcnt - ( H_SYNCTIME + H_BACK - 1'b1 ) ;
						address_y <= vcnt - ( V_SYNCTIME + V_BACK ) ;
					end
				else
					begin
						address_x <= address_x ;
						address_y <= address_y ;
					end
			end
	end

//这部分代码是得到显示部分的行列坐标。因为VGA显示有一些同步和消隐，这些地方是不显示内容的。其中列范围从0到799，行范围为0到499.
reg [16:0] addra;
always@(*) 
	begin
		if(address_x >=100 && address_x <= 299 &&
		address_y >=100 && address_y <= 299 )
			addra = (address_y-100)*200 + (address_x-100) ;
		else
			addra = 0;
	end
//synthesis attribute box_type <rom> "rom_ceshi"
wire [2:0] douta ;
wire locked;
clk_wiz_0 instance_name(
// Clock out ports  
  .clk_40M(clk_40M),
  // Status and control signals               
  .locked(locked),
 // Clock in ports
  .clk_in1(clk_in1)
);
drink_1 pictre_rom_u1 (
	.clka(clk_40M), // input clka
	.addra(addra), // input [16 : 0] addra
	.douta(douta) // output [2 : 0] douta
	);
	//这里就是一个rom的例化，将地址输入，得到输出的数据。
	always@(* )
		begin
			if(enable)
				begin
					case( douta )
						3'b000 :
							begin
								red <= 0 ;
								blue <= 0 ;
								gree <= 0 ;
							end
						3'b001 :
							begin
								red <= 0 ;
								blue <= 1 ;
								gree <= 0 ;
							end
						3'b010 :
							begin
								red <= 0 ;
								blue <= 0 ;
								gree <= 1 ;
							end
						3'b011 :
							begin
								red <= 0 ;
								blue <= 1 ;
								gree <= 1 ;
							end
						3'b100 :
							begin
								red <= 1 ;
								blue <= 0 ;
								gree <= 0 ;
							end
						3'b101 :
							begin
								red <= 1 ;
								blue <= 1 ;
								gree <= 0 ;
							end
						3'b110 :
							begin
								red <= 1 ;
								blue <= 0 ;
								gree <= 1 ;
							end
						3'b111 :
							begin
								red <= 1 ;
								blue <= 1 ;
								gree <= 1 ;
							end
						default :
							begin
								red <= red ;
								blue <= blue ;
								gree <= gree ;
							end
					endcase
				end
			else
				begin
					red <= 0 ;
					blue <= 0 ;
					gree <= 0 ;
				end
		end
	assign red_0 = red;
	assign red_1 = red;
	assign red_2 = red;
	assign red_3 = red;
	assign gree_0 = gree;
	assign gree_1 = gree;
	assign gree_2 = gree;
	assign gree_3 = gree;
	assign blue_0 = blue;
	assign blue_1 = blue;
	assign blue_2 = blue;
	assign blue_3 = blue;
endmodule
