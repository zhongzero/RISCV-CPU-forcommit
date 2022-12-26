//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"
module Reg (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* do_ins_queue() */
	// insQueue
	input wire [`DATA_WIDTH] order_rs1,
	input wire [`DATA_WIDTH] order_rs2,

	output reg reg_busy_order_rs1,
	output reg reg_busy_order_rs2,
	output reg [`DATA_WIDTH] reg_reorder_order_rs1,
	output reg [`DATA_WIDTH] reg_reorder_order_rs2,
	output reg [`DATA_WIDTH] reg_reg_order_rs1,
	output reg [`DATA_WIDTH] reg_reg_order_rs2,

	input wire insqueue_to_Reg_needchange,
	input wire [`DATA_WIDTH] order_rd,

	input wire reg_busy_order_rd_,
	input wire [`DATA_WIDTH] reg_reorder_order_rd_,

	/* do_ROB() */
	//ROB
	input wire [`DATA_WIDTH] commit_rd,

	output reg reg_busy_commit_rd,
	output reg [`ROB_LR_WIDTH] reg_reorder_commit_rd,
	
	input wire ROB_to_Reg_needchange,
	input wire ROB_to_Reg_needchange2,
	
	input wire [`DATA_WIDTH] reg_reg_commit_rd_,
	input wire reg_busy_commit_rd_
);

// always @(*) begin
// 	$display("Reg        ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end


reg [`DATA_WIDTH] reg_reg[`MaxReg-1:0];
reg [`DATA_WIDTH] reg_reorder[`MaxReg-1:0];
reg reg_busy[`MaxReg-1:0];

//wire [`DATA_WIDTH] reg0=reg_reg[0];//for_debug
//wire [`DATA_WIDTH] reg1=reg_reg[1];//for_debug
//wire [`DATA_WIDTH] reg2=reg_reg[2];//for_debug
//wire [`DATA_WIDTH] reg3=reg_reg[3];//for_debug
//wire [`DATA_WIDTH] reg4=reg_reg[4];//for_debug
//wire [`DATA_WIDTH] reg5=reg_reg[5];//for_debug
//wire [`DATA_WIDTH] reg6=reg_reg[6];//for_debug
//wire [`DATA_WIDTH] reg7=reg_reg[7];//for_debug
//wire [`DATA_WIDTH] reg8=reg_reg[8];//for_debug
//wire [`DATA_WIDTH] reg9=reg_reg[9];//for_debug
//wire [`DATA_WIDTH] reg10=reg_reg[10];//for_debug
//wire [`DATA_WIDTH] reg11=reg_reg[11];//for_debug
//wire [`DATA_WIDTH] reg12=reg_reg[12];//for_debug
//wire [`DATA_WIDTH] reg13=reg_reg[13];//for_debug
//wire [`DATA_WIDTH] reg14=reg_reg[14];//for_debug
//wire [`DATA_WIDTH] reg15=reg_reg[15];//for_debug
//wire [`DATA_WIDTH] reg16=reg_reg[16];//for_debug
//wire [`DATA_WIDTH] reg17=reg_reg[17];//for_debug
//wire [`DATA_WIDTH] reg18=reg_reg[18];//for_debug
//wire [`DATA_WIDTH] reg19=reg_reg[19];//for_debug
//wire [`DATA_WIDTH] reg20=reg_reg[20];//for_debug
//wire [`DATA_WIDTH] reg21=reg_reg[21];//for_debug
//wire [`DATA_WIDTH] reg22=reg_reg[22];//for_debug
//wire [`DATA_WIDTH] reg23=reg_reg[23];//for_debug
//wire [`DATA_WIDTH] reg24=reg_reg[24];//for_debug
//wire [`DATA_WIDTH] reg25=reg_reg[25];//for_debug
//wire [`DATA_WIDTH] reg26=reg_reg[26];//for_debug
//wire [`DATA_WIDTH] reg27=reg_reg[27];//for_debug
//wire [`DATA_WIDTH] reg28=reg_reg[28];//for_debug
//wire [`DATA_WIDTH] reg29=reg_reg[29];//for_debug
//wire [`DATA_WIDTH] reg30=reg_reg[30];//for_debug
//wire [`DATA_WIDTH] reg31=reg_reg[31];//for_debug
//wire reg_busy15=reg_busy[15];//for_debug



integer i;

always @(*) begin
	reg_busy_order_rs1=reg_busy[order_rs1];
	reg_busy_order_rs2=reg_busy[order_rs2];
	reg_reorder_order_rs1=reg_reorder[order_rs1];
	reg_reorder_order_rs2=reg_reorder[order_rs2];
	reg_reg_order_rs1=reg_reg[order_rs1];
	reg_reg_order_rs2=reg_reg[order_rs2];
end

always @(*) begin
	reg_busy_commit_rd=reg_busy[commit_rd];
	reg_reorder_commit_rd=reg_reorder[commit_rd];
end

always @(posedge clk) begin
	if(rst) begin
		// Reg
		for(i=0;i<`MaxReg;i=i+1) begin
			reg_reg[i]<=0;
			reg_reorder[i]<=0;
			reg_busy[i]<=0;
		end
	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		for(i=0;i<`MaxReg;i=i+1)reg_busy[i]<=0;
	end
	else begin
		// from insqueue
		if(insqueue_to_Reg_needchange) begin
			if(order_rd!=0) begin //0号寄存器强制�?0
				reg_busy[order_rd]<=reg_busy_order_rd_;
				reg_reorder[order_rd]<=reg_reorder_order_rd_;
			end
		end
		// from ROB
		if(ROB_to_Reg_needchange) begin
			if(commit_rd!=0) begin //0号寄存器强制�?0
				reg_reg[commit_rd]<=reg_reg_commit_rd_;
				if(ROB_to_Reg_needchange2) begin
					if(!insqueue_to_Reg_needchange || commit_rd!=order_rd) begin //insqueue对reg的修改的优先级比ROB更高
						reg_busy[commit_rd]<=reg_busy_commit_rd_;
					end
				end
			end
		end
	end
end



endmodule