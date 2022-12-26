//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "E://RISCV-CPU/CPU/src/info.v"

module Decode (
	input wire [`DATA_WIDTH] inst,
	output reg [`INST_TYPE_WIDTH] order_type,
	output reg [`DATA_WIDTH] order_rd,
	output reg [`DATA_WIDTH] order_rs1,
	output reg [`DATA_WIDTH] order_rs2,
	output reg [`DATA_WIDTH] order_imm
);
wire [6:0] type1;
wire [2:0] type2;
wire [6:0] type3;
assign type1=inst[6:0];
assign type2=inst[14:12];
assign type3=inst[31:25];
always @(*) begin
	order_rd=inst[11:7];
	order_rs1=inst[19:15];
	order_rs2=inst[24:20];
	
	order_imm=0;//for_latch
	order_type=0;//for_latch
	
	if(type1==7'h37||type1==7'h17) begin //U类型
		if(type1==7'h37)order_type=`LUI;
		if(type1==7'h17)order_type=`AUIPC;
		order_imm={inst[31:12],12'b0};
	end

	if(type1==7'h33) begin //R类型
		if(type2==3'h0) begin
			if(type3==7'h00)order_type=`ADD;
			if(type3==7'h20)order_type=`SUB;
		end
		if(type2==3'h1)order_type=`SLL;
		if(type2==3'h2)order_type=`SLT;
		if(type2==3'h3)order_type=`SLTU;
		if(type2==3'h4)order_type=`XOR;
		if(type2==3'h5) begin
			if(type3==7'h00)order_type=`SRL;
			if(type3==7'h20)order_type=`SRA;
		end
		if(type2==3'h6)order_type=`OR;
		if(type2==3'h7)order_type=`AND;
	end

	if(type1==7'h67||type1==7'h03||type1==7'h13) begin //I类型
		if(type1==7'h67)order_type=`JALR;
		if(type1==7'h03) begin
			if(type2==3'h0)order_type=`LB;
			if(type2==3'h1)order_type=`LH;
			if(type2==3'h2)order_type=`LW;
			if(type2==3'h4)order_type=`LBU;
			if(type2==3'h5)order_type=`LHU;
		end
		if(type1==7'h13) begin
			if(type2==3'h0)order_type=`ADDI;
			if(type2==3'h2)order_type=`SLTI;
			if(type2==3'h3)order_type=`SLTIU;
			if(type2==3'h4)order_type=`XORI;
			if(type2==3'h6)order_type=`ORI;
			if(type2==3'h7)order_type=`ANDI;
			if(type2==3'h1)order_type=`SLLI;
			if(type2==3'h5) begin
				if(type3==7'h00)order_type=`SRLI;
				if(type3==7'h20)order_type=`SRAI;
			end
		end
		order_imm[31:0]={20'b0,inst[31:20]};
		if(order_type==`SRAI)order_imm[10]=0;
	end

	if(type1==7'h23) begin //S类型
		if(type2==3'h0)order_type=`SB;
		if(type2==3'h1)order_type=`SH;
		if(type2==3'h2)order_type=`SW;
		order_imm[31:0]={20'b0,inst[31:25],inst[11:7]};
	end

	if(type1==7'h6f) begin //J类型
		order_type=`JAL;
		order_imm[31:0]={11'b0,inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
	end

	if(type1==7'h63) begin //B类型
		if(type2==3'h0)order_type=`BEQ;
		if(type2==3'h1)order_type=`BNE;
		if(type2==3'h4)order_type=`BLT;
		if(type2==3'h5)order_type=`BGE;
		if(type2==3'h6)order_type=`BLTU;
		if(type2==3'h7)order_type=`BGEU;
		order_imm[31:0]={19'd0,inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
	end

	if(order_type==`JALR||order_type==`LB||order_type==`LH||order_type==`LW||order_type==`LBU||order_type==`LHU) begin
		if(order_imm>>11)order_imm=order_imm|32'hfffff000;
	end
	if(order_type==`ADDI||order_type==`SLTI||order_type==`SLTIU||order_type==`XORI||order_type==`ORI||order_type==`ANDI) begin
		if(order_imm[11])order_imm[31:12]=20'hfffff;
	end
	if(order_type==`SB||order_type==`SH||order_type==`SW) begin
		if(order_imm[11])order_imm[31:12]=20'hfffff;
	end
	if(order_type==`JAL) begin
		if(order_imm[20])order_imm[31:21]=11'h7ff;
	end
	if(order_type==`BEQ||order_type==`BNE||order_type==`BLT||order_type==`BGE||order_type==`BLTU||order_type==`BGEU) begin
		if(order_imm[12])order_imm[31:13]=19'h7ffff;
	end
end

endmodule