//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"

module IsLoad (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Load
);
always @(*) begin
	if(type==`LB||type==`LH||type==`LW||type==`LBU||type==`LHU)
		is_Load=1;
	else is_Load=0;
end

endmodule