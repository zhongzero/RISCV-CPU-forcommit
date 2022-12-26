//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "E://RISCV-CPU/CPU/src/info.v"

module IsBranch (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Branch
);
always @(*) begin
	if(type==`BEQ||type==`BNE||type==`BLT||type==`BGE||type==`BLTU||type==`BGEU||type==`JAL||type==`JALR)
		is_Branch=1;
	else is_Branch=0;
end

endmodule