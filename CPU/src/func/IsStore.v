//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "E://RISCV-CPU/CPU/src/info.v"

module IsStore (
	input wire [`INST_TYPE_WIDTH] type,
	output reg is_Store
);
always @(*) begin
	if(type==`SB||type==`SH||type==`SW)
		is_Store=1;
	else is_Store=0;
end

endmodule