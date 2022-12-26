//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
 `include "info.v"

module EX (
	input wire [`INST_TYPE_WIDTH] ordertype,
	input wire [`DATA_WIDTH] vj,
	input wire [`DATA_WIDTH] vk,
	input wire [`DATA_WIDTH] A,
	input wire [`DATA_WIDTH] pc,
	output reg [`DATA_WIDTH] value,
	output reg [`DATA_WIDTH] jumppc
);
always @(*) begin
    
    if(ordertype==`JALR)jumppc=(vj+A)&(~1);
    else jumppc=0;//for_latch
    
	if(ordertype==`LUI)value=A;
	else if(ordertype==`AUIPC)value=pc+A;

	else if(ordertype==`ADD)value=vj+vk;
	else if(ordertype==`SUB)value=vj-vk;
	else if(ordertype==`SLL)value=vj<<(vk&5'h1f);
	else if(ordertype==`SLT)value=($signed(vj)<$signed(vk))?1:0;
	else if(ordertype==`SLTU)value=(vj<vk)?1:0;
	else if(ordertype==`XOR)value=vj^vk;
	else if(ordertype==`SRL)value=vj>>(vk&5'h1f);
	else if(ordertype==`SRA)value=$signed(vj)>>(vk&5'h1f);
	else if(ordertype==`OR)value=vj|vk;
	else if(ordertype==`AND)value=vj&vk;

	else if(ordertype==`JALR) begin
//		jumppc=(vj+A)&(~1);
		value=pc+4;
	end


	else if(ordertype==`ADDI)value=vj+A;
	else if(ordertype==`SLTI)value=($signed(vj)<$signed(A))?1:0;
	else if(ordertype==`SLTIU)value=(vj<A)?1:0;
	else if(ordertype==`XORI)value=vj^A;
	else if(ordertype==`ORI)value=vj|A;
	else if(ordertype==`ANDI)value=vj&A;
	else if(ordertype==`SLLI)value=vj<<A;
	else if(ordertype==`SRLI)value=vj>>A;
	else if(ordertype==`SRAI)value=$signed(vj)>>A;
	

	else if(ordertype==`JAL) begin
		value=pc+4;
	end


	else if(ordertype==`BEQ) begin
		value=(vj==vk?1:0);
	end
	else if(ordertype==`BNE) begin
		value=(vj!=vk?1:0);
	end
	else if(ordertype==`BLT) begin
		value=($signed(vj)<$signed(vk)?1:0);
	end
	else if(ordertype==`BGE) begin
		value=($signed(vj)>=$signed(vk)?1:0);
	end
	else if(ordertype==`BLTU) begin
		value=(vj<vk?1:0);
	end
	else if(ordertype==`BGEU) begin
		value=(vj>=vk?1:0);
	end
	else value=0;//for_latch
end

endmodule