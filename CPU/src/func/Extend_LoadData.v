//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "E://RISCV-CPU/CPU/src/info.v"

module Extend_LoadData (
	input wire [`INST_TYPE_WIDTH] tmp_ordertype,
	input wire [`DATA_WIDTH] data,
	output reg [`DATA_WIDTH] ans
);
always @(*) begin
	//signed:符号位扩展，unsigned�?0扩展
	ans=data;
	if(tmp_ordertype==`LB) begin
		if(data[7])ans[31:8]=24'hffffff;
		else ans[31:8]=24'h000000;
	end
	if(tmp_ordertype==`LH) begin
		if(data[15])ans[31:16]=16'hffff;
		else ans[31:16]=16'h0000;
	end
	if(tmp_ordertype==`LW)ans=data;
	if(tmp_ordertype==`LBU)ans[31:8]=24'h000000;
	if(tmp_ordertype==`LHU)ans[31:16]=16'h0000;
end

endmodule