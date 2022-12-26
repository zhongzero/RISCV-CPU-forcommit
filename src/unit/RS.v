//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"

// `include "/RISCV-CPU/CPU/src/func/EX.v"
module RS (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* do_RS() */
	//ROB and SLB
	output reg [`ROB_LR_WIDTH] b2,

	//ROB
	output reg RS_to_ROB_needchange,
	output reg RS_to_ROB_needchange2,

	output reg [`DATA_WIDTH] ROB_s_value_b2_,
	output reg ROB_s_ready_b2_,
	output reg [`DATA_WIDTH] ROB_s_jumppc_b2_,

	//SLB
	output reg RS_to_SLB_needchange,
	output reg [`DATA_WIDTH] RS_to_SLB_value,


	/* do_ins_queue() */
	//insqueue
	output reg [`RS_LR_WIDTH] RS_unbusy_pos,

	input wire insqueue_to_RS_needchange,
	input wire [`RS_LR_WIDTH] r2,

	input wire [`DATA_WIDTH] RS_s_vj_r2_,
	input wire [`DATA_WIDTH] RS_s_vk_r2_,
	input wire [`DATA_WIDTH] RS_s_qj_r2_,
	input wire [`DATA_WIDTH] RS_s_qk_r2_,
	input wire [`DATA_WIDTH] RS_s_inst_r2_,
	input wire [`INST_TYPE_WIDTH] RS_s_ordertype_r2_,
	input wire [`DATA_WIDTH] RS_s_pc_r2_,
	input wire [`DATA_WIDTH] RS_s_jumppc_r2_,
	input wire [`DATA_WIDTH] RS_s_A_r2_,
	input wire [`DATA_WIDTH] RS_s_reorder_r2_,
	input wire RS_s_busy_r2_,

	/* do_ROB() */
	//ROB
	input wire [`ROB_LR_WIDTH] b3,
	input wire ROB_to_RS_needchange,
	input wire [`DATA_WIDTH] ROB_to_RS_value_b3,



	/* do_SLB() */
	//SLB
	input wire SLB_to_RS_needchange,
	input wire [`DATA_WIDTH] SLB_to_RS_loadvalue,
	input wire [`ROB_LR_WIDTH] b4
);


// always @(*) begin
// 	$display("RS         ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end

reg [`INST_TYPE_WIDTH] RS_s_ordertype[`MaxRS-1:0];
//reg [`DATA_WIDTH] RS_s_inst[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_pc[`MaxRS-1:0];
//reg [`DATA_WIDTH] RS_s_jumppc[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_vj[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_vk[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_qj[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_qk[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_A[`MaxRS-1:0];
reg [`DATA_WIDTH] RS_s_reorder[`MaxRS-1:0];
reg RS_s_busy[`MaxRS-1:0];




integer i,j;

reg [`RS_LR_WIDTH] RS_id;
wire [`DATA_WIDTH] value;
wire [`DATA_WIDTH] jumppc;
//wire [`INST_TYPE_WIDTH] tmp_ordertype=RS_s_ordertype[RS_id];//for_debug
EX u_EX(
    .ordertype ( RS_s_ordertype[RS_id] ),
    .vj        ( RS_s_vj[RS_id]        ),
    .vk        ( RS_s_vk[RS_id]        ),
    .A         ( RS_s_A[RS_id]         ),
    .pc        ( RS_s_pc[RS_id]        ),
    .value     ( value     ),
    .jumppc    ( jumppc    )
);


// do_RS() part1
always @(*) begin
	RS_to_ROB_needchange=0;
	RS_to_ROB_needchange2=0;
	RS_to_SLB_needchange=0;
	
	b2=0;//for_latch
	ROB_s_value_b2_=0;//for_latch
	ROB_s_ready_b2_=0;//for_latch
	ROB_s_jumppc_b2_=0;//for_latch
	RS_to_SLB_value=0;//for_latch

	RS_id=-1;
	for(i=`MaxRS-1;i>=0;i=i-1) begin
		if(RS_s_busy[i]&&RS_s_qj[i]==-1&&RS_s_qk[i]==-1) begin
			RS_id=i;
		end
	end
	// `MaxRS=32
	// $display("RS         ","RS_id=",RS_id);
	if(RS_id!=-1) begin
		// EX(RS_s[RS_id];value;jumppc);

		// 修改 ROB
		b2=RS_s_reorder[RS_id];
		RS_to_ROB_needchange=1;
		ROB_s_value_b2_=value ; ROB_s_ready_b2_=1;
		if(RS_s_ordertype[RS_id]==`JALR) begin
			RS_to_ROB_needchange2=1;
			ROB_s_jumppc_b2_=jumppc;
		end

		// 修改 SLB
		RS_to_SLB_needchange=1;
		RS_to_SLB_value=value;
		// for(i=0;i<`MaxSLB;i++) begin
		// 	if(SLB_s_qj_i==b2) begin
		// 		SLB_s_qj_i_=-1;SLB_s_vj_i_=value;
		// 	end
		// 	if(SLB_s_qk_i==b2) begin
		// 		SLB_s_qk_i_=-1;SLB_s_vk_i_=value;
		// 	end
		// end
	end
end


always @(*) begin
	RS_unbusy_pos=-1;
	for(j=`MaxRS-1;j>=0;j=j-1) begin
		if(!RS_s_busy[j]) begin
			RS_unbusy_pos=j;
		end
	end
end

always @(posedge clk) begin
	if(rst) begin
		// RS
		for(i=0;i<`MaxRS;i=i+1) begin
			RS_s_ordertype[i]<=0;
//			RS_s_inst[i]<=0;
			RS_s_pc[i]<=0;
//			RS_s_jumppc[i]<=0;
			RS_s_vj[i]<=0;
			RS_s_vk[i]<=0;
			RS_s_qj[i]<=-1;
			RS_s_qk[i]<=-1;
			RS_s_A[i]<=0;
			RS_s_reorder[i]<=0;
			RS_s_busy[i]<=0;
		end
	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		for(i=0;i<`MaxRS;i=i+1) begin
			RS_s_busy[i]<=0;
			RS_s_qj[i]<=-1;RS_s_qk[i]<=-1;
		end
	end
	else begin
		// do_RS() part2
		if(RS_id!=-1) begin
			// 修改 RS
			RS_s_busy[RS_id]<=0;
			for(i=0;i<`MaxRS;i=i+1) begin
				if(RS_s_busy[i]) begin
					if(RS_s_qj[i]==b2) begin
						RS_s_qj[i]<=-1;RS_s_vj[i]<=value;
					end
					if(RS_s_qk[i]==b2) begin
						RS_s_qk[i]<=-1;RS_s_vk[i]<=value;
					end
				end
			end
		end


		// from insqueue
		if(insqueue_to_RS_needchange) begin
			RS_s_vj[r2]<=RS_s_vj_r2_;
			RS_s_vk[r2]<=RS_s_vk_r2_;
			RS_s_qj[r2]<=RS_s_qj_r2_;
			RS_s_qk[r2]<=RS_s_qk_r2_;
//			RS_s_inst[r2]<=RS_s_inst_r2_;
			RS_s_ordertype[r2]<=RS_s_ordertype_r2_;
			RS_s_pc[r2]<=RS_s_pc_r2_;
//			RS_s_jumppc[r2]<=RS_s_jumppc_r2_;
			RS_s_A[r2]<=RS_s_A_r2_;
			RS_s_reorder[r2]<=RS_s_reorder_r2_;
			RS_s_busy[r2]<=RS_s_busy_r2_;
		end

		// from ROB
		if(ROB_to_RS_needchange) begin
			for(i=0;i<`MaxRS;i=i+1) begin
				if(RS_s_busy[i]) begin
					if(RS_s_qj[i]==b3) begin
						RS_s_qj[i]<=-1;RS_s_vj[i]<=ROB_to_RS_value_b3;
					end
					if(RS_s_qk[i]==b3) begin
						RS_s_qk[i]<=-1;RS_s_vk[i]<=ROB_to_RS_value_b3;
					end
				end
			end
		end

		//from SLB
		if(SLB_to_RS_needchange) begin
			for(i=0;i<`MaxRS;i=i+1) begin
				if(RS_s_busy[i]) begin
					if(RS_s_qj[i]==b4) begin
						RS_s_qj[i]<=-1;RS_s_vj[i]<=SLB_to_RS_loadvalue;
					end
					if(RS_s_qk[i]==b4) begin
						RS_s_qk[i]<=-1;RS_s_vk[i]<=SLB_to_RS_loadvalue;
					end
				end
			end
		end
	end
end



endmodule