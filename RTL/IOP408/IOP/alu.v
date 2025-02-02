module alu(
input wire [7:0]ds1,
input wire [7:0]ds2,
input wire [7:0]imm,

//控制线1，运算控制
input wire alu_add,
input wire alu_sub,
input wire alu_and,
input wire alu_or,
input wire alu_xor,
input wire alu_sr,
input wire alu_sl,
input wire alu_sra,
input wire alu_slt,
input wire alu_eq,
input wire alu_neq,
input wire unsign,		//无符号运算

input wire bra,			//跳转指令

output wire [7:0]alu_out,
output wire branch		//跳转允许

);

wire [7:0]data_add;		//加法运算
wire [7:0]data_sub;
wire [7:0]data_and;
wire [7:0]data_or;
wire [7:0]data_xor;
wire data_slt;
wire data_eq;
wire data_neq;
wire [7:0]data_shift;	//移位指令

wire [7:0]alu_compare;	//比较
wire ds1_equal_ds2;
wire ds1_great_than_ds2;
wire ds1_light_than_ds2;

wire [7:0]ds2_data;		//ds2数据选择
wire [7:0]inv;		//取反
wire [7:0]add_1;	//+1s

//移位指令
wire [7:0]shift_evel1;
wire [7:0]shift_evel2;




assign data_add	=	ds1 + ds2_data;
//对DS2取补码
assign inv		=	~ds1;
assign add_1	=	inv	+ 8'b1;
//当是减法时，DS2切换到DS2取得补码
assign ds2_data	=	alu_sub ? add_1 : ds2;

assign data_sub	=	alu_add;
assign data_and			=	ds1	& ds2;			//当需要进行清零操作时候，ds2的数据被按位取反，此时是CSRRCx指令，DS1是CSR，DS2是RS1
assign data_or			=	ds1 | ds2;
assign data_xor			=	ds1 ^ ds2;
assign data_slt			=	ds1_light_than_ds2;
assign data_eq			=	ds1_equal_ds2;
assign data_neq			=	!ds1_equal_ds2;

//判断ds2和ds1的相等
assign ds1_light_than_ds2	=	!unsign&((ds1[7]&!ds2[7])|				//ds1是负数，ds2是正数（有符号）
								(ds1[7]==ds2[7]) & (ds1 < ds2))|			//ds1，ds2同符号（有符号）
								unsign&(ds1 < ds2);							//无符号比较
assign ds1_great_than_ds2	=	!unsign&((!ds1[7]&ds2[7])|				//ds1正，ds2负
								(ds1[7]==ds2[7]) & (ds1 > ds2))|			//有符号时候同号比较
								unsign&(ds1 < ds2);							//无符号时直接比较大小
assign ds1_equal_ds2		=	(ds1 == ds2);



//移位指令
//筒形移位器
assign shift_evel1=(
    (ds2[0])?
    (alu_sr?{{1{ds1[7]&!unsign}},ds1[7:1]}:{ds1[6:0],1'b0}):
    (ds1));
assign shift_evel2=(
    (ds2[1])?
    (alu_sr?{{1{shift_evel1[7]&!unsign}},shift_evel1[7:1]}:{shift_evel1[6:0],1'b0}):
    (shift_evel1));
assign data_shift=(
    (ds2[2])?
    (alu_sr?{{1{shift_evel2[7]&!unsign}},shift_evel2[7:1]}:{shift_evel1[6:0],1'b0}):
    (shift_evel2));


assign branch	=	bra & ds1[0];		//rs1 bit0=1则跳转

assign alu_out			=	(alu_add 	? data_add 	: 8'b0)|		//加
							(alu_sub 	? data_sub 	: 8'b0)|		//减
							(alu_and	? data_and 	: 8'b0)|		//逻辑&
							(alu_or 	? data_or 	: 8'b0)|		//逻辑|
							(alu_xor 	? data_xor 	: 8'b0)|		//逻辑^
							(alu_slt 	? {6'b0,data_slt} 	: 8'b0)|		//比较大小
							(alu_eq		? {6'b0,data_eq}	: 8'b0)|		//相等
							(alu_neq	? {6'b0,data_neq}	: 8'b0)|		//不相等
							((alu_sr|alu_sl)?data_shift	: 8'b0)|imm;	//移位
							



endmodule