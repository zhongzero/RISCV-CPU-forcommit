//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"
module ICache (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* Get_ins_to_queue() */
	//   Search_In_ICache()
	//insqueue
	input wire [`DATA_WIDTH] addr1,
	output reg hit,
	output reg [`DATA_WIDTH] returnInst,

	/* Get_ins_to_queue() */
	//   Store_In_ICache()
	//insqueue
	input wire insqueue_to_ICache_needchange,
	input wire [`DATA_WIDTH] addr2,
	input wire [`DATA_WIDTH] storeInst
);


// always @(*) begin
// 	$display("ICache     ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end

reg icache_valid[`MaxICache-1:0];
reg [`ICache_TAG_WIDTH] icache_tag[`MaxICache-1:0];
reg [`DATA_WIDTH] icache_inst[`MaxICache-1:0];

integer i,j;

//wire icache_valid0=icache_valid[0];//for_debug


reg [`ICacheIndexSize-1:0] b5;

// Search_In_ICache()
always @(*) begin
    returnInst=0;//for_latch
    
	b5=addr1[`ICacheIndexSize-1:0];
	if(icache_valid[b5]&&icache_tag[b5]==addr1[31:`ICacheIndexSize]) begin
		hit=1;
		returnInst=icache_inst[b5];
	end
	else hit=0;
//	hit=0;
end

reg [`ICacheIndexSize-1:0] b6;

// Store_In_ICache() part1
always @(*) begin
	b6=addr2[`ICacheIndexSize-1:0];
end

always @(posedge clk) begin
	if(rst) begin
		// ICache
		for(i=0;i<`MaxICache;i=i+1) begin
			icache_valid[i]<=0;
			icache_tag[i]<=0;
			icache_inst[i]<=0;
		end
	end
	else if(~rdy) begin
	end
	else begin
		// Store_In_ICache() part2
		if(insqueue_to_ICache_needchange) begin
			icache_valid[b6]<=1;
			icache_tag[b6]<=addr2[31:`ICacheIndexSize];
			icache_inst[b6]<=storeInst;
		end
	end

end



endmodule