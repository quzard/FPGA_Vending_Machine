相关变量
geiwei_tou
shiwei_tou
shiwei_zhaoling
geiwei_zhaoling
reg[9:0]  toubi,huafei;
    	reg[15:0] goumai_1;
    	reg[15:0] goumai_2;
    	reg [3:0] state;



//购买阶段，花费
shiwei_temp
geiwei_temp
shiwei<=shiwei+goumai_num*shiwei_temp;
geiwei<=geiwei+goumai_num*geiwei_temp;
huafei<=shiwei*10+geiwei;



//投币阶段
geiwei_tou
shiwei_tou
toubi<=(shiwei_tou+geiwei_tou);

//退币阶段
geiwei_zhaoling
shiwei_zhaoling

5'b10000//上4
5'b01000//下3
5'b00100//中2
5'b00010//左1
5'b00001//右0

input CLK,
	input RSTn,
	input [4:0]button,
	input [15:0]sw;
	output reg [7:0]geiwei_tou,shiwei_tou,shiwei,geiwei,shiwei_zhaoling,geiwei_zhaoling,num
    );




