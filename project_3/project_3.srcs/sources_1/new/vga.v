//1、分频模块：
module fenpin(
    input CLK,
    input RSTn,
    output reg CLK_50M
    );
	always @ (posedge CLK or negedge RSTn )
	    if( !RSTn )
	        begin
	            CLK_50M <= 0;
	        end
	    else
	        CLK_50M<=~CLK_50M;
endmodule

//2、按键消抖模块：
module key_delay(  
	clk,
	rst_n, 
	key_in, 
	button_out
	);
	input  clk;
	input rst_n;
	input  [4:0]key_in;
	output [4:0]button_out;
	//寄存器定义
	reg [19:0]count;
	reg [4:0] key_scan;
	//核心程序
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			count <=20'd0;
		else//20ms为去抖时间
	        begin
	            if(count === 20'd999_999)
	                begin
	                    count <= 20'd0;
	                    key_scan <= key_in;
	                end 
	            else 
	                count <= count + 20'd1;
	        end
	end
	reg[4:0]key_scan_r;
	always@(posedge clk)
		key_scan_r <= key_scan;
		
	wire [4:0]flag_key = key_scan_r[4:0]&(~key_scan[4:0]);
	reg [4:0]temp_led;
	always @ (posedge clk or negedge rst_n) //检测时钟的上升沿和复位的下降沿
		begin
			if (!rst_n) 
				temp_led <= 5'b00000;
			else
				begin
					if ( flag_key[0] ) temp_led=5'b00001; 
					else if ( flag_key[1] ) temp_led=5'b00010; 
					else if ( flag_key[2] ) temp_led=5'b00100; 
					else if ( flag_key[3] ) temp_led=5'b01000; 
					else if ( flag_key[4] ) temp_led=5'b10000; 
					else temp_led=5'b00000; 
				end
		end
	assign button_out[0] = temp_led[0];
	assign button_out[1] = temp_led[1];
	assign button_out[2] = temp_led[2];
	assign button_out[3] = temp_led[3];
	assign button_out[4] = temp_led[4];
endmodule
//3.拨码开关消抖
module boma_delay(     
    input CLK,
    input RSTn,
    input [15:0] sw_in,
    output reg [15:0] sw_out=0
    );
    reg [1:0]next_state;
    reg [15:0]sw_temp;//表示sw_temp的bit位宽为16，最高位为第15位，最低位为0
    reg time_20ms;//位宽默认为1bit
    reg is_count;
    reg [28:0] count;
    always @ ( posedge CLK or negedge RSTn )
	    if( !RSTn )
		    begin
			    sw_temp <= 16'b0000000000000000;
			    next_state <= 2'd0;
			    is_count     <= 1'b0;
			    sw_out <= 16'b0000000000000000;
		    end
	    else
		    begin
			    case(next_state) 
				    2'b00:
					    if(sw_in!==16'b0000000000000000)//有按键输入
						    begin
							    next_state<= 2'd1;
							    is_count<= 1'b1;//开始计数
							    sw_temp<= sw_in;
						    end
						else
						    begin
							    next_state<= 2'd0;
							    sw_temp<= 16'b0000000000000000;
							    is_count<= 1'b0;
						    end
				    2'b01:
					    if(time_20ms===1'b1 )//按键维持了20ms
					    	begin
							    is_count<= 1'b0;//结束计数
							    next_state<= 2'd2;
					    	end
					    else
					    	begin
					    		sw_temp<= sw_in;
					    		if(sw_in!==sw_temp)
					    			begin
					    				is_count<=1'b0;
					    				next_state<= 2'd0;
					    			end
					    		else
								    begin
									    next_state<= 2'd1;
									    is_count<= 1'b1;//开始计数
								    end
					    	end
				    2'b10:
					    if(sw_in!==sw_temp || sw_in===16'b0000000000000000)//按键松开
						    begin
							    sw_out<= sw_temp;    
							    next_state<= 2'd3;
						    end
					    else
						    begin 
							    sw_out<= 16'b0000000000000000;
							    next_state<= 2'd2;
						    end
				    2'b11:
				    	begin
						    next_state<= 2'd0;
						    sw_out<= 16'b0000000000000000;
				    	end
				    default:
				    	next_state<= 2'd0;
			    endcase

			 end
	always @ ( posedge CLK or negedge RSTn )
		if(!RSTn)
		    begin
			    time_20ms<=1'b0;
			    count<=28'd0;
		    end
		else if(is_count===1'b1)
		    if(count===28'd100000)
			    begin
				    time_20ms<=1'b1;
				    count<=28'd0;
			    end
		    else
			    begin
				    time_20ms<=1'b0;
				    count<=count+1'd1;//
			    end
		else
		    begin
			    time_20ms<=1'b0;
			    count<=28'd0;
	    	end
endmodule
//4.VGA控制模块：
module sync_module(
	input CLK,
	input RSTn,
	output VSYNC_Sig,
	output HSYNC_Sig,
	output Ready_Sig,
	output [10:0]Column_Addr_Sig,
	output [10:0]Row_Addr_Sig
	);
	reg [10:0]Count_H;
	always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
			Count_H <= 11'd0;
		else if( Count_H === 11'd1055  )//1055=80+160+800+16-1
			Count_H <= 11'd0;
		else
			Count_H <= Count_H +1'b1;      
	reg [10:0]Count_V;
	always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
			Count_V <= 11'd0;
		else if( Count_V === 11'd624 )//624=3+21+600+1-1
			Count_V <= 11'd0;
		else if( Count_H === 11'd1055 )//1055=80+160+800+16-1
			Count_V <= Count_V +1'b1;
	reg isReady;
	always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
			isReady <= 1'b0;
			//当行计数或场计数处于控制区时是RGB输出全为零，消隐
			//240=80+160,1040=60+160+800,24=3+21,624=3+21+600
		else if( ( Count_H > 11'd240&& Count_H < 11'd1040 ) &&(Count_V >11'd24 && Count_V < 11'd624 ) )
			isReady <= 1'b1;
		else
			isReady <= 1'b0;
			
	//产生场同步信号，VSYNC_Sig低电平有效
	//4=3+1,81=80+1
	assign VSYNC_Sig = ( Count_V < 11'd4 )? 1'b0 : 1'b1;//场计数值为0-1时产生场同步信号，低电平有效
	//产生行同步信号 ，HSYNC_Sig低电平有效
	assign HSYNC_Sig = ( Count_H < 11'd81) ? 1'b0 : 1'b1;//行计数值为0-95之间产生行同步信号，低电平有效
	
	assign Ready_Sig = isReady;
	//241=80+160+1,25=3+21+1
	assign Column_Addr_Sig = isReady ?Count_H - 11'd241 : 11'd0;
	assign Row_Addr_Sig = isReady ? Count_V -11'd25 : 11'd0;
endmodule

//5.VGA显示模块
module vga_control_module(
    input CLK,
    input RSTn,
    input Ready_Sig,
    input [10:0] lie,
    input [10:0] hang,
    
    input [15:0] wupin,
    output reg [11:0] rgb,
    input [3:0] geiwei_tou,
    input [3:0] shiwei_tou,
    input [3:0] shiwei,
    input [3:0] geiwei,
    input [3:0] shiwei_zhaoling,
    input [3:0] geiwei_zhaoling,
    input [4:0] num
    );
	reg [511:0] num_0 =512'h00000000000000000000000003C006200C30181818181808300C300C300C300C300C300C300C300C300C300C1808181818180C30062003C00000000000000000;
    reg [511:0] num_1 =512'h000000000000000000000000008001801F800180018001800180018001800180018001800180018001800180018001800180018003C01FF80000000000000000;
    reg [511:0] num_2 =512'h00000000000000000000000007E008381018200C200C300C300C000C001800180030006000C0018003000200040408041004200C3FF83FF80000000000000000;
	reg [511:0] num_3 =512'h00000000000000000000000007C018603030301830183018001800180030006003C0007000180008000C000C300C300C30083018183007C00000000000000000;
	reg [511:0] num_4 =512'h0000000000000000000000000060006000E000E0016001600260046004600860086010603060206040607FFC0060006000600060006003FC0000000000000000;
	reg [511:0] num_5 =512'h0000000000000000000000000FFC0FFC10001000100010001000100013E0143018181008000C000C000C000C300C300C20182018183007C00000000000000000;
	reg [511:0] num_6 =512'h00000000000000000000000001E006180C180818180010001000300033E0363038183808300C300C300C300C300C180C18080C180E3003E00000000000000000;
	reg [511:0] num_7 =512'h0000000000000000000000001FFC1FFC100830102010202000200040004000400080008001000100010001000300030003000300030003000000000000000000;
	reg [511:0] num_8 =512'h00000000000000000000000007E00C301818300C300C300C380C38081E180F2007C018F030783038601C600C600C600C600C3018183007C00000000000000000;
	reg [511:0] num_9 =512'h00000000000000000000000007C01820301030186008600C600C600C600C600C701C302C186C0F8C000C0018001800103030306030C00F800000000000000000;
	reg [1023:0] hua  =1024'h00000000000000000010100000181C000018180000181800001818383FFFFFFC0018180000181800001818000030100000300000006030000060302000C03070018030E001C0338003C0370006C03C000CC0380008C0F00030C3300040CC300800C0300800C0300800C0300800C0300C00C03FFC00C03FFC0080000000000000;
	reg [1023:0] fei  =1024'h000000000000000000082000000C3000000C30400FFFFFE0000C3060000C3040000C304003FFFFC0060C3060060C30080FFFFFFC0418301800303010006030F00180316006FFFFC018C2030000C1830000C1830000C1830000C3030000C3030000C3030000063800000C0F00001803C0007001E001C000E01E00004000000000;
	reg [1023:0] tou  =1024'h00000000000000000100000001C080000180FFC00180C1800180C1800180C1800190C1803FF8818001818180018181800181018C018300FE019E004001E7FFE0018880C00F8080C03D8041803180418001802300018023000180360001801E0001801C0001803E00018067000181C1E00F8300FE030C00380070000000000000;
	reg [1023:0] bi   =1024'h00000000000000000000008000000FC00001FFE007FF8000000180000001800000018000000180000201802003FFFFF0030180600301806003018060030180600301806003018060030180600301806003018060030180600301806003018860030187E0030181C0020180000001800000018000000180000001800000000000;
	reg [1023:0] zhao =1024'h00000000000000000080400000E0380000C0230000C021C000C020E000C0206000C820003FFC200000C0203800C3FFC000C4200000C0200000C4206000F8306001C030E00FC031C07CC0338030C0370000C01E0000C01C0000C0380800C06C0800C0CE0800C1070800C6038810D801D80F8000F80380003C0100000C00000000;
	reg [1023:0] ling =1024'h00000000000000000000008003FFFFC0000180000001800007FFFFF80C0180180C0180301801802019F99F80000100000000000003F91F800003800000078000000C4000003C300000731C0001C187F00E0080FC3000801003FFFE0000000F000000180000206000001E80000003C0000000F000000038000000180000000000;
	reg [1023:0] yuan =1024'h0000000000000000000000000000008003FFFFC0000000000000000000000000000000000000000000000000000000301FFFFFF8000C3000000830000018300000183000001830000018300000183000003030080030300800303008006030080060300800C030080180301C03003FFC06001FF8180000002000000000000000;
	reg [1023:0] shu  =1024'h00000000000000000060080000700E000C618C00066318000766180002641000006910083FFFFFFC00E0306001F83060016E7060026650600462904018609040204108C000E008C000C208C03FFF0C8001860D8001060580030C0700038C070000780700003F0D8000E318E0018130700600C03E380100100006000000000000;
	reg [1023:0] liang=1024'h00000000000000000000010001FFFF80018001000180010001FFFF00018001000180010001FFFF0001800180010000087FFFFFFC000000000000000001FFFF80018181800181818001FFFF8001818180018181800181818001FFFF8001818100000180C007FFFFE00001800000018000000180183FFFFFFC0000000000000000;
    wire[7:0] pic_Data;    
    reg [20:0] pic_Addr; 
    reg [11:0] rgb_temp;
    
    reg [511:0]num_geiwei_tou;//q[1]
    reg [511:0]num_shiwei_tou;//q[0]
    reg [511:0]num_shiwei;//q[2]
    reg [511:0]num_geiwei;//q[3]
    reg [511:0]num_shiwei_zhaoling;//q[4]
    reg [511:0]num_geiwei_zhaoling;//q[5]
    reg [511:0]num_shuliang;//q[7]

    /**************16个框****************/
       wire k1_1,k2_1,k3_1,k4_1,k5_1,k6_1,k7_1,k8_1,k9_1,k10_1,k11_1,k12_1,k13_1,k14_1,k15_1,k16_1; //框1、2、3
       wire k1_2,k2_2,k3_2,k4_2,k5_2,k6_2,k7_2,k8_2,k9_2,k10_2,k11_2,k12_2,k13_2,k14_2,k15_2,k16_2;
       assign k1_1=(((94<=lie &&lie<99)||(179<=lie && lie<184))&&(25<=hang&& hang<115))?1'b1:1'b0;
       assign k2_1=(((268<=lie &&lie<273)||(353<=lie && lie<358))&&(25<=hang&& hang<115))?1'b1:1'b0;
       assign k3_1=(((442<=lie &&lie<447)||(527<=lie && lie<532))&&(25<=hang&& hang<115))?1'b1:1'b0;
       assign k4_1=(((616<=lie &&lie<621)||(701<=lie && lie<706))&&(25<=hang&& hang<115))?1'b1:1'b0;
       assign k1_2=((99<=lie &&lie<179)&&((25<=hang && hang<30)||(110<=hang&& hang<115)))?1'b1:1'b0;
       assign k2_2=((273<=lie &&lie<353)&&((25<=hang && hang<30)||(110<=hang&& hang<115)))?1'b1:1'b0;
       assign k3_2=((447<=lie &&lie<527)&&((25<=hang && hang<30)||(110<=hang&& hang<115)))?1'b1:1'b0;
       assign k4_2=((621<=lie &&lie<701)&&((25<=hang && hang<30)||(110<=hang&& hang<115)))?1'b1:1'b0;

       assign k5_1=(((94<=lie &&lie<99)||(179<=lie && lie<184))&&(155<=hang&& hang<245))?1'b1:1'b0;
       assign k6_1=(((268<=lie &&lie<273)||(353<=lie && lie<358))&&(155<=hang&& hang<245))?1'b1:1'b0;
       assign k7_1=(((442<=lie &&lie<447)||(527<=lie && lie<532))&&(155<=hang&& hang<245))?1'b1:1'b0;
       assign k8_1=(((616<=lie &&lie<621)||(701<=lie && lie<706))&&(155<=hang&& hang<245))?1'b1:1'b0;
       assign k5_2=((99<=lie &&lie<179)&&((155<=hang && hang<160)||(240<=hang&& hang<245)))?1'b1:1'b0;
       assign k6_2=((273<=lie &&lie<353)&&((155<=hang && hang<160)||(240<=hang&& hang<245)))?1'b1:1'b0;
       assign k7_2=((447<=lie &&lie<527)&&((155<=hang && hang<160)||(240<=hang&& hang<245)))?1'b1:1'b0;
       assign k8_2=((621<=lie &&lie<701)&&((155<=hang && hang<160)||(240<=hang&& hang<245)))?1'b1:1'b0;

       assign k9_1=(((94<=lie &&lie<99)||(179<=lie && lie<184))&&(285<=hang&& hang<375))?1'b1:1'b0;
       assign k10_1=(((268<=lie &&lie<273)||(353<=lie && lie<358))&&(285<=hang&& hang<375))?1'b1:1'b0;
       assign k11_1=(((442<=lie &&lie<447)||(527<=lie && lie<532))&&(285<=hang&& hang<375))?1'b1:1'b0;
       assign k12_1=(((616<=lie &&lie<621)||(701<=lie && lie<706))&&(285<=hang&& hang<375))?1'b1:1'b0;
       assign k9_2=((99<=lie &&lie<179)&&((285<=hang && hang<290)||(370<=hang&& hang<375)))?1'b1:1'b0;
       assign k10_2=((273<=lie &&lie<353)&&((285<=hang && hang<290)||(370<=hang&& hang<375)))?1'b1:1'b0;
       assign k11_2=((447<=lie &&lie<527)&&((285<=hang && hang<290)||(370<=hang&& hang<375)))?1'b1:1'b0;
       assign k12_2=((621<=lie &&lie<701)&&((285<=hang && hang<290)||(370<=hang&& hang<375)))?1'b1:1'b0;

       assign k13_1=(((94<=lie &&lie<99)||(179<=lie && lie<184))&&(415<=hang&& hang<505))?1'b1:1'b0;
       assign k14_1=(((268<=lie &&lie<273)||(353<=lie && lie<358))&&(415<=hang&& hang<505))?1'b1:1'b0;
       assign k15_1=(((442<=lie &&lie<447)||(527<=lie && lie<532))&&(415<=hang&& hang<505))?1'b1:1'b0;
       assign k16_1=(((616<=lie &&lie<621)||(701<=lie && lie<706))&&(415<=hang&& hang<505))?1'b1:1'b0;
       assign k13_2=((99<=lie &&lie<179)&&((415<=hang && hang<420)||(500<=hang&& hang<505)))?1'b1:1'b0;
       assign k14_2=((273<=lie &&lie<353)&&((415<=hang && hang<420)||(500<=hang&& hang<505)))?1'b1:1'b0;
       assign k15_2=((447<=lie &&lie<527)&&((415<=hang && hang<420)||(500<=hang&& hang<505)))?1'b1:1'b0;
       assign k16_2=((621<=lie &&lie<701)&&((415<=hang && hang<420)||(500<=hang&& hang<505)))?1'b1:1'b0;



       /**************4个图片****************/
       wire pic1,pic2,pic3,pic4;       //图片1、2、3、4
       wire pich_1;                            //图片的行
       assign pich_1=(30<=hang &&hang<110)?1'b1:1'b0;
       assign pic1=((99<=lie &&lie<179)&&(pich_1===1'b1))?1'b1:1'b0;
       assign pic2=((273<=lie &&lie<353)&&(pich_1===1'b1))?1'b1:1'b0;
       assign pic3=((447<=lie &&lie<527)&&(pich_1===1'b1))?1'b1:1'b0;
       assign pic4=((621<=lie &&lie<701)&&(pich_1===1'b1))?1'b1:1'b0;
       /**************4个图片****************/
       wire pic5,pic6,pic7,pic8;       //图片5、6、7、8
       wire pich_2;                            //图片的行
       assign pich_2=(160<=hang &&hang<240)?1'b1:1'b0;
       assign pic5=((99<=lie &&lie<179)&&(pich_2===1'b1))?1'b1:1'b0;
       assign pic6=((273<=lie &&lie<353)&&(pich_2===1'b1))?1'b1:1'b0;
       assign pic7=((447<=lie &&lie<527)&&(pich_2===1'b1))?1'b1:1'b0;
       assign pic8=((621<=lie &&lie<701)&&(pich_2===1'b1))?1'b1:1'b0;
       /**************4个图片****************/
       wire pic9,pic10,pic11,pic12;       //图片9、10、11、12
       wire pich_3;                            //图片的行
       assign pich_3=(290<=hang &&hang<370)?1'b1:1'b0;
       assign pic9=((99<=lie &&lie<179)&&(pich_3===1'b1))?1'b1:1'b0;
       assign pic10=((273<=lie &&lie<353)&&(pich_3===1'b1))?1'b1:1'b0;
       assign pic11=((447<=lie &&lie<527)&&(pich_3===1'b1))?1'b1:1'b0;
       assign pic12=((621<=lie &&lie<701)&&(pich_3===1'b1))?1'b1:1'b0;
       /**************4个图片****************/
       wire pic13,pic14,pic15,pic16;       //图片13、14、15、16
       wire pich_4;                            //图片的行
       assign pich_4=(420<=hang &&hang<500)?1'b1:1'b0;
       assign pic13=((99<=lie &&lie<179)&&(pich_4===1'b1))?1'b1:1'b0;
       assign pic14=((273<=lie &&lie<353)&&(pich_4===1'b1))?1'b1:1'b0;
       assign pic15=((447<=lie &&lie<527)&&(pich_4===1'b1))?1'b1:1'b0;
       assign pic16=((621<=lie &&lie<701)&&(pich_4===1'b1))?1'b1:1'b0;
       /**************4个单价****************/
       wire [1:0]dj1,dj2,dj3,dj4;//单价1、2、3、4
       wire dah_1;                             //单价的行
       assign dah_1=(119<=hang &&hang<151)?1'b1:1'b0;
       assign dj1[0]=((107<=lie &&lie<123)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj1[1]=((123<=lie &&lie<139)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj2[0]=((281<=lie &&lie<297)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj2[1]=((297<=lie &&lie<313)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj3[0]=((455<=lie &&lie<471)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj3[1]=((471<=lie &&lie<487)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj4[0]=((629<=lie &&lie<645)&&(dah_1===1'b1))?1'b1:1'b0;
       assign dj4[1]=((645<=lie &&lie<661)&&(dah_1===1'b1))?1'b1:1'b0;
       /**************4个单价****************/
       wire [1:0]dj5,dj6,dj7,dj8;//单价5,6,7,8
       wire dah_2;                             //单价的行
       assign dah_2=(249<=hang &&hang<281)?1'b1:1'b0;
       assign dj5[0]=((107<=lie &&lie<123)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj5[1]=((123<=lie &&lie<139)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj6[0]=((281<=lie &&lie<297)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj6[1]=((297<=lie &&lie<313)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj7[0]=((455<=lie &&lie<471)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj7[1]=((471<=lie &&lie<487)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj8[0]=((629<=lie &&lie<645)&&(dah_2===1'b1))?1'b1:1'b0;
       assign dj8[1]=((645<=lie &&lie<661)&&(dah_2===1'b1))?1'b1:1'b0;
       /**************4个单价****************/
       wire [1:0]dj9,dj10,dj11,dj12;//单价9,10,11,12
       wire dah_3;                             //单价的行
       assign dah_3=(379<=hang &&hang<411)?1'b1:1'b0;
       assign dj9[0]=((107<=lie &&lie<123)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj9[1]=((123<=lie &&lie<139)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj10[0]=((281<=lie &&lie<297)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj10[1]=((297<=lie &&lie<313)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj11[0]=((455<=lie &&lie<471)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj11[1]=((471<=lie &&lie<487)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj12[0]=((629<=lie &&lie<645)&&(dah_3===1'b1))?1'b1:1'b0;
       assign dj12[1]=((645<=lie &&lie<661)&&(dah_3===1'b1))?1'b1:1'b0;
       /**************4个单价****************/
       wire [1:0]dj13,dj14,dj15,dj16;//单价13,14,15,16
       wire dah_4;                             //单价的行
       assign dah_4=(509<=hang &&hang<541)?1'b1:1'b0;
       assign dj13[0]=((107<=lie &&lie<123)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj13[1]=((123<=lie &&lie<139)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj14[0]=((281<=lie &&lie<297)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj14[1]=((297<=lie &&lie<313)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj15[0]=((455<=lie &&lie<471)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj15[1]=((471<=lie &&lie<487)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj16[0]=((629<=lie &&lie<645)&&(dah_4===1'b1))?1'b1:1'b0;
       assign dj16[1]=((645<=lie &&lie<661)&&(dah_4===1'b1))?1'b1:1'b0;
       /**************17个字符****************投币，花费，找零，和3个元,8个钱的输入*/
       wire t,b,h,f,z,l,sh,li;              //投币，花费，找零,数量
       wire [2:0]y;                         //3个"元"
       wire [7:0]q;                         //8个钱
       //wire [1:0]xsd;               //2个小数点
       assign t     =(30<=lie && lie <62 && 554<=hang &&hang<586 )?1'b1:1'b0;//投
       assign b     =(62<=lie && lie <94 && 554<=hang &&hang<586 )?1'b1:1'b0;//币
       assign q[0]  =(104<=lie && lie <120 && 554<=hang&& hang<586 )?1'b1:1'b0;//投币-十位
       assign q[1]  =(120<=lie && lie <136 && 554<=hang&& hang<586 )?1'b1:1'b0;//投币-个位
       assign y[0]  =(136<=lie && lie <168 && 554<=hang&& hang<586 )?1'b1:1'b0;//元

       assign h     =(220<=lie && lie <252 && 554<=hang &&hang<586 )?1'b1:1'b0;//花
       assign f     =(252<=lie && lie <284 && 554<=hang &&hang<586 )?1'b1:1'b0;//费
       assign q[2]  =(294<=lie && lie <310 && 554<=hang&& hang<586 )?1'b1:1'b0;//花费-十位
       assign q[3]  =(310<=lie && lie <326 && 554<=hang&& hang<586 )?1'b1:1'b0;//花费-个位
       assign y[1]  =(326<=lie && lie <358 && 554<=hang&& hang<586 )?1'b1:1'b0;//元

       assign z     =(410<=lie && lie <442 && 554<=hang &&hang<586 )?1'b1:1'b0;//找
       assign l     =(442<=lie && lie <474 && 554<=hang &&hang<586 )?1'b1:1'b0;//零
       assign q[4]  =(484<=lie && lie <500 && 554<=hang&& hang<586 )?1'b1:1'b0;//找零-十位
       assign q[5]  =(500<=lie && lie <516 && 554<=hang&& hang<586 )?1'b1:1'b0;//找零-个位
       assign y[2]  =(516<=lie && lie <548 && 554<=hang&& hang<586 )?1'b1:1'b0;//元

       assign sh    =(600<=lie && lie <632 && 554<=hang &&hang<586 )?1'b1:1'b0;//数
       assign li    =(632<=lie && lie <664 && 554<=hang &&hang<586 )?1'b1:1'b0;//量
       assign q[6]  =(674<=lie && lie <690 && 554<=hang&& hang<586 )?1'b1:1'b0;//数量-十位
       assign q[7]  =(690<=lie && lie <706 && 554<=hang&& hang<586 )?1'b1:1'b0;//数量-个位


    pic pictre_rom_u1 (
         .clka(CLK), // input clka 
        .addra(pic_Addr), // input [16 : 0] addra
         .douta(pic_Data) // output [2 : 0] douta
         );
    always@(* )
		begin
			if(Ready_Sig&&(pic1|pic2|pic3|pic4|pic5|pic6|pic7|pic8|pic9|pic10|pic11|pic12|pic13|pic14|pic15|pic16))
				begin
					case( pic_Data )
						3'b000 :
							begin
								rgb_temp<=12'b000000000000;
							end
						3'b001 :
							begin
								rgb_temp<=12'b000000001111;
							end
						3'b010 :
							begin
								rgb_temp<=12'b000011110000;
							end
						3'b011 :
							begin
								rgb_temp<=12'b000011111111;
							end
						3'b100 :
							begin
								rgb_temp<=12'b111100000000;
							end
						3'b101 :
							begin
								rgb_temp<=12'b111100001111;
							end
						3'b110 :
							begin
								rgb_temp<=12'b111111110000;
							end
						3'b111 :
							begin
								rgb_temp<=12'b111111111111;
							end
						default :
							begin
								rgb_temp<=rgb_temp;
							end
					endcase
				end
			else
				begin
					rgb_temp=12'b000000000000;
				end
			case(num)
				4'b0000:num_shuliang=num_0;
				4'b0001:num_shuliang=num_1;
				4'b0010:num_shuliang=num_2;
				4'b0011:num_shuliang=num_3;
				4'b0100:num_shuliang=num_4;
				4'b0101:num_shuliang=num_5;
				4'b0110:num_shuliang=num_6;
				4'b0111:num_shuliang=num_7;
				4'b1000:num_shuliang=num_8;
				4'b1001:num_shuliang=num_9;
				default:num_shuliang=num_0;
			endcase

			case(geiwei_tou)
				4'b0000:num_geiwei_tou=num_0;
				4'b0001:num_geiwei_tou=num_1;
				4'b0010:num_geiwei_tou=num_2;
				4'b0011:num_geiwei_tou=num_3;
				4'b0100:num_geiwei_tou=num_4;
				4'b0101:num_geiwei_tou=num_5;
				4'b0110:num_geiwei_tou=num_6;
				4'b0111:num_geiwei_tou=num_7;
				4'b1000:num_geiwei_tou=num_8;
				4'b1001:num_geiwei_tou=num_9;
				default:num_geiwei_tou=num_0;
			endcase
			case(shiwei_tou)
				4'b0000:num_shiwei_tou=num_0;
				4'b0001:num_shiwei_tou=num_1;
				4'b0010:num_shiwei_tou=num_2;
				4'b0011:num_shiwei_tou=num_3;
				4'b0100:num_shiwei_tou=num_4;
				4'b0101:num_shiwei_tou=num_5;
				4'b0110:num_shiwei_tou=num_6;
				4'b0111:num_shiwei_tou=num_7;
				4'b1000:num_shiwei_tou=num_8;
				4'b1001:num_shiwei_tou=num_9;
				default:num_shiwei_tou=num_0;
			endcase
			case(shiwei)
				4'b0000:num_shiwei=num_0;
				4'b0001:num_shiwei=num_1;
				4'b0010:num_shiwei=num_2;
				4'b0011:num_shiwei=num_3;
				4'b0100:num_shiwei=num_4;
				4'b0101:num_shiwei=num_5;
				4'b0110:num_shiwei=num_6;
				4'b0111:num_shiwei=num_7;
				4'b1000:num_shiwei=num_8;
				4'b1001:num_shiwei=num_9;
				default:num_shiwei=num_0;
			endcase
			case(geiwei)
				4'b0000:num_geiwei=num_0;
				4'b0001:num_geiwei=num_1;
				4'b0010:num_geiwei=num_2;
				4'b0011:num_geiwei=num_3;
				4'b0100:num_geiwei=num_4;
				4'b0101:num_geiwei=num_5;
				4'b0110:num_geiwei=num_6;
				4'b0111:num_geiwei=num_7;
				4'b1000:num_geiwei=num_8;
				4'b1001:num_geiwei=num_9;
				default:num_geiwei=num_0;
			endcase
			case(shiwei_zhaoling)
				4'b0000:num_shiwei_zhaoling=num_0;
				4'b0001:num_shiwei_zhaoling=num_1;
				4'b0010:num_shiwei_zhaoling=num_2;
				4'b0011:num_shiwei_zhaoling=num_3;
				4'b0100:num_shiwei_zhaoling=num_4;
				4'b0101:num_shiwei_zhaoling=num_5;
				4'b0110:num_shiwei_zhaoling=num_6;
				4'b0111:num_shiwei_zhaoling=num_7;
				4'b1000:num_shiwei_zhaoling=num_8;
				4'b1001:num_shiwei_zhaoling=num_9;
				default:num_shiwei_zhaoling=num_0;
			endcase
			case(geiwei_zhaoling)
				4'b0000:num_geiwei_zhaoling=num_0;
				4'b0001:num_geiwei_zhaoling=num_1;
				4'b0010:num_geiwei_zhaoling=num_2;
				4'b0011:num_geiwei_zhaoling=num_3;
				4'b0100:num_geiwei_zhaoling=num_4;
				4'b0101:num_geiwei_zhaoling=num_5;
				4'b0110:num_geiwei_zhaoling=num_6;
				4'b0111:num_geiwei_zhaoling=num_7;
				4'b1000:num_geiwei_zhaoling=num_8;
				4'b1001:num_geiwei_zhaoling=num_9;
				default:num_geiwei_zhaoling=num_0;
			endcase
		end
		


    always @ ( posedge CLK or negedge RSTn )
	       if(!RSTn)
	              begin
	                     rgb<=12'b000000000000;
	              end
	       else if(Ready_Sig)
	              begin
	                     if(k1_2|k1_1)//框1
	                            if(wupin[0])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k2_2|k2_1)//框2
	                            if(wupin[1])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k3_1|k3_2)//框3
	                            if(wupin[2])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k4_1|k4_2)//框4
	                            if(wupin[3])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k5_1|k5_2)//框5
	                            if(wupin[4])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k6_1|k6_2)//框6
	                            if(wupin[5])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k7_1|k7_2)//框7
	                            if(wupin[6])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k8_1|k8_2)//框8
	                            if(wupin[7])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k9_1|k9_2)//框9
	                            if(wupin[8])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k10_1|k10_2)//框10
	                            if(wupin[9])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k11_1|k11_2)//框11
	                            if(wupin[10])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k12_1|k12_2)//框12
	                            if(wupin[11])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k13_1|k13_2)//框13
	                            if(wupin[12])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k14_1|k14_2)//框14
	                            if(wupin[13])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k15_1|k15_2)//框15
	                            if(wupin[14])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(k16_1|k16_2)//框16
	                            if(wupin[15])
	                                   rgb<=12'b111100000000;
	                            else
	                                   rgb<=12'b000000000000;
	                     else if(pic1|pic2|pic3|pic4|pic5|pic6|pic7|pic8|pic9|pic10|pic11|pic12|pic13|pic14|pic15|pic16)
		                     begin
			                     case( {pic1,pic2,pic3,pic4,pic5,pic6,pic7,pic8,pic9,pic10,pic11,pic12,pic13,pic14,pic15,pic16} )
				                     16'b1000000000000000: begin pic_Addr=(hang-30)*80+(lie-99);rgb<=rgb_temp;end
				                     16'b0100000000000000: begin pic_Addr=80*80+(hang-30)*80+(lie-273);rgb<=rgb_temp;end
				                     16'b0010000000000000: begin pic_Addr=2*80*80+(hang-30)*80+(lie-447);rgb<=rgb_temp;end
				                     16'b0001000000000000: begin pic_Addr=3*80*80+(hang-30)*80+(lie-621);rgb<=rgb_temp;end
				                     16'b0000100000000000: begin pic_Addr=4*80*80+(hang-160)*80+(lie-99);rgb<=rgb_temp;end
				                     16'b0000010000000000: begin pic_Addr=5*80*80+(hang-160)*80+(lie-273);rgb<=rgb_temp;end
				                     16'b0000001000000000: begin pic_Addr=6*80*80+(hang-160)*80+(lie-447);rgb<=rgb_temp;end
				                     16'b0000000100000000: begin pic_Addr=7*80*80+(hang-160)*80+(lie-621);rgb<=rgb_temp;end
				                     16'b0000000010000000: begin pic_Addr=8*80*80+(hang-290)*80+(lie-99);rgb<=rgb_temp;end
				                     16'b0000000001000000: begin pic_Addr=9*80*80+(hang-290)*80+(lie-273);rgb<=rgb_temp;end
				                     16'b0000000000100000: begin pic_Addr=10*80*80+(hang-290)*80+(lie-447);rgb<=rgb_temp;end
				                     16'b0000000000010000: begin pic_Addr=11*80*80+(hang-290)*80+(lie-621);rgb<=rgb_temp;end
				                     16'b0000000000001000: begin pic_Addr=12*80*80+(hang-420)*80+(lie-99);rgb<=rgb_temp;end
				                     16'b0000000000000100: begin pic_Addr=13*80*80+(hang-420)*80+(lie-273);rgb<=rgb_temp;end
				                     16'b0000000000000010: begin pic_Addr=14*80*80+(hang-420)*80+(lie-447);rgb<=rgb_temp;end
				                     16'b0000000000000001: begin pic_Addr=15*80*80+(hang-420)*80+(lie-621);rgb<=rgb_temp;end
				                     default: begin pic_Addr=0;rgb<=12'b000000000000;end
			                     endcase 
		                     end
	                     else if(dj1[0]|dj1[1])
		                     begin
			                     case(dj1)
				                     2'b01: begin rgb<={12{num_0[511-(lie-107+  (hang-119)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_1[511-(lie-123+  (hang-119)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj2[0]|dj2[1])
		                     begin
			                     case(dj2)
				                     2'b01: begin rgb<={12{num_0[511-(lie-281+  (hang-119)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_2[511-(lie-297+  (hang-119)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj3[0]|dj3[1])
		                     begin
			                     case(dj3)
				                     2'b01: begin rgb<={12{num_0[511-(lie-455+  (hang-119)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_3[511-(lie-471+  (hang-119)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj4[0]|dj4[1])
		                     begin
			                     case(dj4)
				                     2'b01: begin rgb<={12{num_0[511-(lie-629+  (hang-119)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_4[511-(lie-645+  (hang-119)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end

		                 else if(dj5[0]|dj5[1])
		                     begin
			                     case(dj5)
				                     2'b01: begin rgb<={12{num_0[511-(lie-107+  (hang-249)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_5[511-(lie-123+  (hang-249)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj6[0]|dj6[1])
		                     begin
			                     case(dj6)
				                     2'b01: begin rgb<={12{num_0[511-(lie-281+  (hang-249)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_6[511-(lie-297+  (hang-249)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj7[0]|dj7[1])
		                     begin
			                     case(dj7)
				                     2'b01: begin rgb<={12{num_0[511-(lie-455+  (hang-249)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_7[511-(lie-471+  (hang-249)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj8[0]|dj8[1])
		                     begin
			                     case(dj8)
				                     2'b01: begin rgb<={12{num_0[511-(lie-629+  (hang-249)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_8[511-(lie-645+  (hang-249)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end

		                 else if(dj9[0]|dj9[1])
		                     begin
			                     case(dj9)
				                     2'b01: begin rgb<={12{num_0[511-(lie-107+  (hang-379)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_9[511-(lie-123+  (hang-379)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj10[0]|dj10[1])
		                     begin
			                     case(dj10)
				                     2'b01: begin rgb<={12{num_1[511-(lie-281+  (hang-379)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_0[511-(lie-297+  (hang-379)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj11[0]|dj11[1])
		                     begin
			                     case(dj11)
				                     2'b01: begin rgb<={12{num_1[511-(lie-455+  (hang-379)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_1[511-(lie-471+  (hang-379)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj12[0]|dj12[1])
		                     begin
			                     case(dj12)
				                     2'b01: begin rgb<={12{num_1[511-(lie-629+  (hang-379)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_2[511-(lie-645+  (hang-379)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end

		                 else if(dj13[0]|dj13[1])
		                     begin
			                     case(dj13)
				                     2'b01: begin rgb<={12{num_1[511-(lie-107+  (hang-509)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_3[511-(lie-123+  (hang-509)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj14[0]|dj14[1])
		                     begin
			                     case(dj14)
				                     2'b01: begin rgb<={12{num_1[511-(lie-281+  (hang-509)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_4[511-(lie-297+  (hang-509)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj15[0]|dj15[1])
		                     begin
			                     case(dj15)
				                     2'b01: begin rgb<={12{num_1[511-(lie-455+  (hang-509)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_5[511-(lie-471+  (hang-509)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(dj16[0]|dj16[1])
		                     begin
			                     case(dj16)
				                     2'b01: begin rgb<={12{num_1[511-(lie-629+  (hang-509)*16  )  ]}};end
				                     2'b10: begin rgb<={12{num_6[511-(lie-645+  (hang-509)*16  )  ]}};end
				                     default: begin rgb<=12'b000000000000;end
			                     endcase
		                     end
		                 else if(t|h|z)
		                 	begin
		                 		case({t,h,z})
		                 			3'b100:begin rgb<={12{tou[1023-(lie-30+  (hang-554)*32  )  ]}};end
		                 			3'b010:begin rgb<={12{hua[1023-(lie-220+  (hang-554)*32  )  ]}};end
		                 			3'b001:begin rgb<={12{zhao[1023-(lie-410+  (hang-554)*32  )  ]}};end
		                 			default:begin rgb<=12'b000000000000;end
		                 		endcase
		                 	end
	                     else if(b|f|l)
	                     	begin
	                     		case({b,f,l})
	                     			3'b100:begin rgb<={12{bi[1023-(lie-62+  (hang-554)*32  )  ]}};end
		                 			3'b010:begin rgb<={12{fei[1023-(lie-252+  (hang-554)*32  )  ]}};end
		                 			3'b001:begin rgb<={12{ling[1023-(lie-442+  (hang-554)*32  )  ]}};end
		                 			default:begin rgb<=12'b000000000000;end
	                     			endcase
	                     	end
	                     else if(y[0]|y[1]|y[2])
	                     	begin
	                     		case(y)
	                     			3'b100:begin rgb<={12{yuan[1023-(lie-516+  (hang-554)*32  )  ]}};end
		                 			3'b010:begin rgb<={12{yuan[1023-(lie-326+  (hang-554)*32  )  ]}};end
		                 			3'b001:begin rgb<={12{yuan[1023-(lie-136+  (hang-554)*32  )  ]}};end
		                 			default:begin rgb<=12'b000000000000;end
	                     		endcase
	                     	end
	                     else if(q[0]|q[1]|q[2]|q[3]|q[4]|q[5])
	                     	begin
	                     		case(q)
	                     			6'b000001:begin rgb<={12{num_shiwei_tou[1023-(lie-104+  (hang-554)*16  )  ]}};end
	                     			6'b000010:begin rgb<={12{num_geiwei_tou[1023-(lie-120+  (hang-554)*16  )  ]}};end
	                     			6'b000100:begin rgb<={12{num_shiwei[1023-(lie-294+  (hang-554)*16  )  ]}};end
	                     			6'b001000:begin rgb<={12{num_geiwei[1023-(lie-310+  (hang-554)*16  )  ]}};end
	                     			6'b010000:begin rgb<={12{num_shiwei_zhaoling[1023-(lie-484+  (hang-554)*16  )  ]}};end
	                     			6'b100000:begin rgb<={12{num_geiwei_zhaoling[1023-(lie-500+  (hang-554)*16  )  ]}};end
	                     			default:begin rgb<=12'b000000000000;end
	                     		endcase
	                     	end
	                     else if(sh|li|q[6]|q[7])
	                     	begin
	                     		case({sh,li,q[6],q[7]})
	                     			4'b1000:begin rgb<={12{shu[1023-(lie-600+  (hang-554)*32  )  ]}};end
	                     			4'b0100:begin rgb<={12{liang[1023-(lie-632+  (hang-554)*32  )  ]}};end
	                     			4'b0010:begin rgb<={12{num_0[1023-(lie-674+  (hang-554)*16  )  ]}};end
	                     			4'b0001:begin rgb<={12{num_shuliang[1023-(lie-690+  (hang-554)*16  )  ]}};end
	                     			default:begin rgb<=12'b000000000000;end
	                     		endcase
	                     	end
		                 else begin
		                	rgb<=12'b000000000000;
		                 end
	              end
endmodule

//6.销售模块：

module main(
	input CLK,
	input RSTn,
	input [4:0]button,
	input [15:0]sw,
	output reg[15:0] wupin=0,
	output reg[15:0] LED=0,
	output reg[7:0]geiwei_tou=0,
	output reg[7:0]shiwei_tou=0,
	output reg[7:0]shiwei=0,
	output reg[7:0]geiwei=0,
	output reg[7:0]shiwei_zhaoling=0,
	output reg[7:0]geiwei_zhaoling=0,
	output reg[4:0]goumai_num=0
    );
		//state状态  0选择第一件商品，1第一件商品数量，2选择第二件商品，3第二件商品数量，4投币 5确定出货 6找零
    	reg[7:0]  shiwei_temp,geiwei_temp,toubi,huafei,zhaoling;
    	reg [3:0] state;
    	
		always @ ( posedge CLK or negedge RSTn )
			if(!RSTn)
				begin
					state<=4'b0000;
					shiwei_temp<=8'b0;
					geiwei_temp<=8'b0;
					toubi<=8'b0;
					huafei<=8'b0;
					zhaoling<=8'b0;
					goumai_num<=4'd0;
					LED=16'b0000000000000000;
	                geiwei_tou<=8'b0;
	                shiwei_tou<=8'b0;
	                shiwei<=8'b0;
	                geiwei<=8'b0;
	                shiwei_zhaoling<=8'b0;
	                geiwei_zhaoling<=8'b0;
	                wupin=16'b0000000000000000;
	                
	            end
	        else
	            begin
	            	LED=16'b0000000000000000;
	            	if(geiwei_tou>=90)
	                    begin
	                        geiwei_tou=geiwei_tou-90;
	                        shiwei_tou=shiwei_tou+9;
	                    end
	                else if(geiwei_tou>=80)
	                	begin
	                		geiwei_tou=geiwei_tou-80;
	                		shiwei_tou=shiwei_tou+8;
	                	end
	                else if(geiwei_tou>=70)
	                	begin
	                		geiwei_tou=geiwei_tou-70;
	                		shiwei_tou=shiwei_tou+7;
	                	end
	                else if(geiwei_tou>=60)
	                	begin
	                		geiwei_tou=geiwei_tou-60;
	                		shiwei_tou=shiwei_tou+6;
	                	end
	                else if(geiwei_tou>=50)
	                	begin
	                		geiwei_tou=geiwei_tou-50;
	                		shiwei_tou=shiwei_tou+5;
	                	end
	                else if(geiwei_tou>=40)
	                	begin
	                		geiwei_tou=geiwei_tou-40;
	                		shiwei_tou=shiwei_tou+4;
	                	end
	                else if(geiwei_tou>=30)
	                	begin
	                		geiwei_tou=geiwei_tou-30;
	                		shiwei_tou=shiwei_tou+3;
	                	end
	                else if(geiwei_tou>=20)
	                	begin
	                		geiwei_tou=geiwei_tou-20;
	                		shiwei_tou=shiwei_tou+2;
	                	end
	                else if(geiwei_tou>=10)
	                	begin
	                		geiwei_tou=geiwei_tou-10;
	                		shiwei_tou=shiwei_tou+1;
	                	end
	                else begin
	                	
	                end

	                toubi=shiwei_tou*10+geiwei_tou;

	                if(geiwei>=90)
	                    begin
	                        geiwei=geiwei-90;
	                        shiwei=shiwei+9;
	                    end
	                else if(geiwei>=80)
	                	begin
	                		geiwei=geiwei-80;
	                		shiwei=shiwei+8;
	                	end
	                else if(geiwei>=70)
	                	begin
	                		geiwei=geiwei-70;
	                		shiwei=shiwei+7;
	                	end
	                else if(geiwei>=60)
	                	begin
	                		geiwei=geiwei-60;
	                		shiwei=shiwei+6;
	                	end
	                else if(geiwei>=50)
	                	begin
	                		geiwei=geiwei-50;
	                		shiwei=shiwei+5;
	                	end
	                else if(geiwei>=40)
	                	begin
	                		geiwei=geiwei-40;
	                		shiwei=shiwei+4;
	                	end
	                else if(geiwei>=30)
	                	begin
	                		geiwei=geiwei-30;
	                		shiwei=shiwei+3;
	                	end
	                else if(geiwei>=20)
	                	begin
	                		geiwei=geiwei-20;
	                		shiwei=shiwei+2;
	                	end
	                else if(geiwei>=10)
	                	begin
	                		geiwei=geiwei-10;
	                		shiwei=shiwei+1;
	                	end
	                else begin
	                	
	                end

	                huafei=shiwei*10+geiwei;

	                if(geiwei_zhaoling>=90)
	                    begin
	                        geiwei_zhaoling=geiwei_zhaoling-90;
	                        shiwei_zhaoling=shiwei_zhaoling+9;
	                    end
	                else if(geiwei_zhaoling>=80)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-80;
	                		shiwei_zhaoling=shiwei_zhaoling+8;
	                	end
	                else if(geiwei_zhaoling>=70)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-70;
	                		shiwei_zhaoling=shiwei_zhaoling+7;
	                	end
	                else if(geiwei_zhaoling>=60)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-60;
	                		shiwei_zhaoling=shiwei_zhaoling+6;
	                	end
	                else if(geiwei_zhaoling>=50)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-50;
	                		shiwei_zhaoling=shiwei_zhaoling+5;
	                	end
	                else if(geiwei_zhaoling>=40)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-40;
	                		shiwei_zhaoling=shiwei_zhaoling+4;
	                	end
	                else if(geiwei_zhaoling>=30)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-30;
	                		shiwei_zhaoling=shiwei_zhaoling+3;
	                	end
	                else if(geiwei_zhaoling>=20)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-20;
	                		shiwei_zhaoling=shiwei_zhaoling+2;
	                	end
	                else if(geiwei_zhaoling>=10)
	                	begin
	                		geiwei_zhaoling=geiwei_zhaoling-10;
	                		shiwei_zhaoling=shiwei_zhaoling+1;
	                	end
	                else begin
	                	
	                end
	                zhaoling=geiwei_zhaoling+shiwei_zhaoling*10;
	                case(state)
	                	4'b0000://选择商品
	                		begin
	                			LED[0]=1'b1;
	                			case(sw)//选择商品
			                        16'b1000000000000000://16
			                        	begin
			                        		wupin[15]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+6;
			                        		state<=4'b1;
			                        	end
			                        16'b0100000000000000://15
			                        	begin
			                        		wupin[14]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+5;
			                        		state<=4'b1;
			                        	end
			                        16'b0010000000000000://14
			                        	begin
			                        		wupin[13]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+4;
			                        		state<=4'b1;
			                        	end
			                       	16'b0001000000000000://13
			                       		begin
			                       			wupin[12]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+3;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000100000000000://12
			                       		begin
			                       			wupin[11]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+2;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000010000000000://11
			                       		begin
			                       			wupin[10]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		geiwei_temp<=geiwei_temp+1;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000001000000000://10
			                       		begin
			                       			wupin[9]=1'b1;
			                        		shiwei_temp<=shiwei_temp+1;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000100000000://9
			                       		begin
			                       			wupin[8]=1'b1;
			                        		geiwei_temp<=geiwei_temp+9;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000010000000://8
			                       		begin
			                       			wupin[7]=1'b1;
			                        		geiwei_temp<=geiwei_temp+8;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000001000000://7
			                       		begin
			                       			wupin[6]=1'b1;
			                        		geiwei_temp<=geiwei_temp+7;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000100000://6
			                       		begin
			                       			wupin[5]=1'b1;
			                        		geiwei_temp<=geiwei_temp+6;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000010000://5
			                       		begin
			                       			wupin[4]=1'b1;
			                        		geiwei_temp<=geiwei_temp+5;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000001000://4
			                       		begin
			                       			wupin[3]=1'b1;
			                        		geiwei_temp<=geiwei_temp+4;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000000100://3
			                       		begin
			                       			wupin[2]=1'b1;
			                        		geiwei_temp<=geiwei_temp+3;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000000010://2
			                       		begin
			                       			wupin[1]=1'b1;
			                        		geiwei_temp<=geiwei_temp+2;
			                        		state<=4'b1;
			                        	end
			                       	16'b0000000000000001://1
			                       		begin
			                       			wupin[0]=1'b1;
			                        		geiwei_temp<=geiwei_temp+1;
			                        		state<=4'b1;
			                        	end
			                        default:state<=4'b0;
		                    	endcase
	                		end
	                	4'b0001://商品数量
	                		begin
	                			LED[1]=1'b1;
	                			case(button)
	                				5'b00010://左
	                					begin
	                						state<=4'b0001;
	                						LED[15]=1'b1;
	                						if(goumai_num>0)
		                						goumai_num=goumai_num-1;
		                					else
		                						goumai_num=0;
	                					end
	                				5'b00001://右
	                					begin
	                						state<=4'b0001;
	                						LED[14]=1'b1;
	                						if(goumai_num<9)
		                						goumai_num=goumai_num+1;
		                					else
		                						goumai_num=9;
	                					end
	                				5'b00100://确认
	                					begin
	                						LED[13]=1'b1;
	                						state<=4'b0010;
	                					end
	                				default:state<=4'b0001;
	                			endcase
	                		end
	                	4'b0010://确定是否下一次
	                		begin
	                			LED[2]=1'b1;
	                			case(button)
	                				5'b00010://购买本次商品并继续购买//左
			                			begin
			                				state<=4'b0;
			                				shiwei<=shiwei+goumai_num*shiwei_temp;
			                				geiwei<=geiwei+goumai_num*geiwei_temp;
			                				shiwei_temp<=0;
			                				goumai_num<=0;
			                				geiwei_temp<=0;
			                				wupin<=16'b0000000000000000;
			                			end
	                				5'b01000://购买本次商品并不继续购买开始投币//下
		                				begin
			                				state<=4'b0100;
			                				shiwei<=shiwei+goumai_num*shiwei_temp;
			                				geiwei<=geiwei+goumai_num*geiwei_temp;
			                				shiwei_temp<=0;
			                				goumai_num<=0;
			                				geiwei_temp<=0;
			                				wupin<=16'b0000000000000000;
			                			end
	                				5'b00001://不购买本次商品并继续购买//右
		                				begin
		                					state<=4'b0;
		                					goumai_num<=0;
		                					shiwei_temp<=0;
			                				geiwei_temp<=0;
			                				wupin<=16'b0000000000000000;
		                				end
	                				5'b10000://不购买本次商品并不继续购买开始投币//上
		                				begin
		                					state<=4'b0100;
		                					shiwei_temp<=0;
		                					goumai_num<=0;
			                				geiwei_temp<=0;
			                				wupin<=16'b0000000000000000;
		                				end
	                				default: 
			                			begin
			                				state<=4'b0010;
			                			end
			                	endcase
	                		end
	                	4'b0011://
	                		begin
	                			state<=4'b0011;
	                			//LED[3]=1'b1;
	                		end
	            		4'b0100://投币
		            		begin
		            			LED[3]=1'b1;
		            			if(sw===16'b0000000000000001)//取消操作并返回选择商品阶段
			            			begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				shiwei<=0;
			            				geiwei<=0;
			            				huafei<=0;
			            				state<=4'b0;
			            			end
		            			else if(sw===16'b0000000000000010)//取消操作并开始退币
			            			begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				shiwei<=0;
			            				geiwei<=0;
			            				huafei<=0;
			            				state<=4'b0110;
			            			end
		            			else if(toubi<huafei)
					                begin
					                	state<=4'b0100;
					                	case(button)
						                    5'b10000://一块上
						                        geiwei_tou<=geiwei_tou+1;
						                    5'b01000://五块下
						                        geiwei_tou<=geiwei_tou+5;
						                    5'b00100://十块中
						                        shiwei_tou<=shiwei_tou+1;
						                    5'b00010://20块左
						                    	shiwei_tou<=shiwei_tou+2;
						                    5'b00001://50块右
						                    	shiwei_tou<=shiwei_tou+5;
					                    endcase
					                end
					            else if(toubi>=huafei  )
						            begin
						            	state<=4'b0101;//确定出货阶段
						            end
						        else state<=4'b0100;
		            		end
		            	4'b0101://确定出货
		            		begin
		            			LED[4]=1'b1;
		            			if(sw===16'b0000000000000001)//取消所有商品并返回选择商品阶段
		            				begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				shiwei<=0;
			            				geiwei<=0;
			            				huafei<=0;
			            				state<=4'b0;
			            			end
		            			else if(sw===16'b0000000000000010)//确定出货并开始退币
			            			begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				state<=4'b0110;
			            			end
		            			else if(sw===16'b0000000000000100)//取消操作并继续购买
		            				begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				state<=4'b0;
			            			end
			            		else if(sw===16'b0000000000001000)//取消所有商品并退币
			            			begin
			            				shiwei_temp<=0;
			            				geiwei_temp<=0;
			            				shiwei<=0;
			            				geiwei<=0;
			            				huafei<=0;
			            				state<=4'b0110;
			            			end
		            			else begin
		            				state<=4'b0101;
		            			end
		            		end
		            	4'b0110://找零
		            		begin
		            			LED[5]=1'b1;
		            			if(zhaoling===toubi-huafei)
						            begin
						            	geiwei_tou<=0;
						            	shiwei_tou<=0;
						            	shiwei<=0;
						           		geiwei<=0;
						           		shiwei_zhaoling<=0;
						           		geiwei_zhaoling<=0;
						           		toubi<=0;
						           		huafei<=0;
						           		zhaoling<=0;
						           		state<=4'b0;
						            end
					            else 
					            	begin
					                    if(button===5'b00100)
					                    	begin
					                    		state<=4'b0110;
					                    		if(geiwei_zhaoling===9)
					                    			begin
					                    				geiwei_zhaoling<=0;
					                    				shiwei_zhaoling<=shiwei_zhaoling+1;
					                    			end
					                    		else 
					                    			geiwei_zhaoling<=geiwei_zhaoling+1;
					                    	end
					                end
		            		end
		            	default:
		            		begin
		            			state<=state;
		            		end
			        endcase  
			    end  
       

endmodule


    
//7.顶层模块：

module top( 
	input CLK,RSTn,
    input [4:0]button,//按键
    input [15:0]sw,//拨码开关
    output v,
    output h,
    output [11:0]rgb,   
    output [15:0]LED
    ); 

       wire [15:0]wupin;//物品
       wire CLK_50M;
       wire Ready_Sig;
       wire [10:0]     Column_Addr_Sig;
       wire [10:0]     Row_Addr_Sig;
       wire [4:0]      button_out;
       wire [15:0]	   sw_out;
       
       
       
       wire [7:0] geiwei_tou,shiwei_tou,shiwei,geiwei,shiwei_zhaoling,geiwei_zhaoling,num;
       fenpin U0
       (      CLK,
              RSTn,
              CLK_50M
       );
       key_delay U1
       (      CLK_50M,
              RSTn,
              button,
              button_out
       );
       boma_delay U2
       (      CLK_50M,
     		  RSTn,
      		  sw,
      	      sw_out
    	);
       sync_module U3
       (      CLK_50M,
              RSTn,
              v,
              h,
              Ready_Sig,
              Column_Addr_Sig,
              Row_Addr_Sig
       );
       
       vga_control_module U4
       (      CLK_50M,
              RSTn,
              Ready_Sig,
              Column_Addr_Sig,
              Row_Addr_Sig,
              wupin,
              rgb,
              geiwei_tou,shiwei_tou,shiwei,geiwei,shiwei_zhaoling,geiwei_zhaoling,num
       );
       main U5
       (      CLK_50M,
              RSTn,
              button_out,
              sw_out,
              wupin,
              LED,
              //state,
              geiwei_tou,shiwei_tou,shiwei,geiwei,shiwei_zhaoling,geiwei_zhaoling,num
       );
endmodule
