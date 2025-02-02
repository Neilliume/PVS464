module cr(
input wire clk,
input wire rst,

output wire [15:0]pc_next,
//中断输入
input wire int0,
input wire int1,
input wire int2,
input wire int3,

//多周期控制
input wire mem_read,		//内存访问
input wire mem_write,
input wire mem_ok,

input wire branch,

output reg main_state,

//cr写控制
input wire statu_sel,
input wire ie_sel,
input wire epc_sel,
input wire cpc_sel,
input wire temp_sel,
input wire tcev0_sel,
input wire tcev1_sel,
input wire tcev2_sel,
input wire tcev3_sel,

input wire cr_write,

input wire [15:0]branch_offset,	//偏移地址
//特殊功能控制
input wire ret,	//返回
input wire apc,	//获取pc值
input wire jmp,		//跳转
input wire bra,		//分支

input wire [15:0]r6_r7_data,
output wire [15:0]cr_data

);

wire int_acc;		//中断发生
wire [15:0]tvec;

wire int0_acc;
wire int1_acc;
wire int2_acc;
wire int3_acc;

//STATU寄存器
reg GIE;
reg PGIE;
//IE寄存器
reg IE0;
reg IE1;
reg IE2;
reg IE3;
//PC
reg [15:0]PC;
//EPC寄存器
reg [15:0]EPC;
//CPC寄存器
reg [15:0]CPC;
//TEMP寄存器
reg [15:0]TEMP;
//TVEC寄存器
reg [15:0]TVEC0;

reg [15:0]TVEC1;
reg [15:0]TVEC2;
reg [15:0]TVEC3;


//main_state
always@(posedge clk)begin
	if(rst)begin
		main_state 	<=	1'b0;
	end
	else if(!main_state)begin		//如果是内存访问，则跳转到T1
		main_state	<=	(mem_read | mem_write) ? 1'b1 : 1'b0;
	end
	else if(main_state)begin		//如果内存访问完成，返回T0
		main_state	<=	mem_ok ? 1'b0 : main_state;
	end
end

//STATU寄存器
always@(posedge clk)begin
	if(rst | int_acc)begin
		GIE	<=	1'b0;
	end
	else if(ret)begin
		GIE	<=	PGIE;
	end
	else if(statu_sel & cr_write)begin
		GIE	<=	r6_r7_data[0];
	end
end

always@(posedge clk)begin
	if(rst)begin
		PGIE	<=	1'b0;
	end
	else if(int_acc)begin
		PGIE	<=	GIE;
	end
	else if(statu_sel & cr_write)begin
		PGIE	<=	r6_r7_data[1];
	end
end

//IE寄存器
always@(posedge clk)begin
	if(rst)begin
		IE0	<=	1'b0;
		IE1	<=	1'b0;
		IE2	<=	1'b0;
		IE3	<=	1'b0;
	end
	else if(ie_sel & cr_write)begin
		IE0	<=	r6_r7_data[0];
		IE1	<=	r6_r7_data[1];
		IE2	<=	r6_r7_data[2];
		IE3	<=	r6_r7_data[3];
	end
end
//EPC寄存器
always@(posedge clk)begin
	if(rst)begin
		EPC	<=	16'b0;
	end
	else if(int_acc)begin	//发生中断时，EPC更新为下一个没有被执行的PC地址
		EPC <=	PC;			//我们把执行访问内存，跳转，分支全部遮蔽中断
	end
	else if(epc_sel & cr_write)begin
		EPC	<=	r6_r7_data;
	end
end
//CPC
always@(posedge clk)begin	
	if(rst)begin
		CPC	<=	16'b0;
	end
	else if(apc)begin
		CPC	<=	PC;
	end
	else if(cpc_sel & cr_write)begin
		CPC	<=	r6_r7_data;
	end
end
//PC
always@(posedge clk)begin
	if(rst)begin
		PC	<=	16'b0;
	end
	else if(int_acc)begin
		PC 	<=	tvec + 16'b1;	//中断接受时，PC同样向后跳2个
	end
	else if(ret)begin
		PC	<=	EPC	+	16'b1;
	end
	else if(jmp)begin
		PC 	<=	r6_r7_data + 1'b1;
	end
	else if(branch)begin		//分支时 PC直接跳2个
		PC	<=	PC + branch_offset + 16'b1;
	end
	else begin					//如果是T0时刻，并且没有内存访问，或者是在T1时刻内存访问结束，PC自动+1
		PC 	<=	((!main_state & !(mem_read|mem_write)) | (main_state & mem_ok)) ? PC + 8'b1 : PC;
	end
end

//TVEC0
always@ (posedge clk)begin
	if(rst)begin
		TVEC0	<=	16'b0;
	end
	else if(tcev0_sel & cr_write)begin
		TVEC0	<=	r6_r7_data;
	end
end

//TVEC1
always@ (posedge clk)begin
	if(rst)begin
		TVEC1	<=	16'b0;
	end
	else if(tcev1_sel & cr_write)begin
		TVEC1	<=	r6_r7_data;
	end
end
//TVEC2
always@ (posedge clk)begin
	if(rst)begin
		TVEC2	<=	16'b0;
	end
	else if(tcev2_sel & cr_write)begin
		TVEC2	<=	r6_r7_data;
	end
end
//TVEC3
always@ (posedge clk)begin
	if(rst)begin
		TVEC3	<=	16'b0;
	end
	else if(tcev3_sel & cr_write)begin
		TVEC3	<=	r6_r7_data;
	end
end

assign int0_acc	=	GIE & int0 & IE0;
assign int1_acc	=	GIE & int1 & IE1;
assign int2_acc	=	GIE & int2 & IE2;
assign int3_acc	=	GIE & int3 & IE3;
						
assign int_acc	=	!(bra | jmp | ret | mem_read|mem_write) & (int0_acc | int1_acc | int2_acc | int3_acc);//只有在没有发生会造成PC更改的指令时进行中断接受

assign tvec	=	int0_acc ? TVEC0 : int1_acc ? TVEC1 : int2_acc ? TVEC2 : TVEC3;

//下一个PC
assign pc_next	=	ret ? EPC : branch ? (PC + branch_offset) : jmp ? (r6_r7_data) : PC;

assign cr_data	=	(statu_sel ? {14'b0,PGIE,GIE} : 16'b0) |
					(ie_sel	   ? {12'b0,IE3,IE2,IE1,IE0} : 16'b0)	|
					(epc_sel	?	EPC	:	16'b0)	|
					(cpc_sel	?	CPC :	16'b0)	|
					(tcev0_sel	?	TVEC0	:	16'b0)	|
					(tcev1_sel	?	TVEC1	:	16'b0)	|
					(tcev2_sel	?	TVEC2	:	16'b0)	|
					(tcev3_sel	?	TVEC3	:	16'b0);
				




endmodule
