//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"

// `include "/RISCV-CPU/CPU/src/func/Extend_LoadData.v"
// `include "/RISCV-CPU/CPU/src/func/IsLoad.v"
module SLB (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	
	/* do_SLB() */
	//RS and ROB
	output reg [`ROB_LR_WIDTH] b4,

	//memctrl
	input wire memctrl_data_ok,
	input wire [`DATA_WIDTH] memctrl_data_ans,

	output reg SLB_to_memctrl_needchange,//load
	output reg SLB_to_memctrl_needchange2,//store

	output reg [`INST_TYPE_WIDTH] SLB_to_memctrl_ordertype,
	output reg [`DATA_WIDTH] SLB_to_memctrl_vj,
	output reg [`DATA_WIDTH] SLB_to_memctrl_vk,
	output reg [`DATA_WIDTH] SLB_to_memctrl_A,

	//ROB
	output reg SLB_to_ROB_needchange,
	output reg [`DATA_WIDTH] ROB_s_value_b4_,
	output reg ROB_s_ready_b4_,

	//RS
	output reg SLB_to_RS_needchange,
	output reg [`DATA_WIDTH] SLB_to_RS_loadvalue,



	/* do_ins_queue() */
	//insqueue

	output reg [`SLB_LR_WIDTH] SLB_size__,
	output reg [`SLB_LR_WIDTH] SLB_R__,

	input wire insqueue_to_SLB_needchange,
	input wire insqueue_to_SLB_size_addflag,
	input wire [`SLB_LR_WIDTH] r1,

	input wire [`SLB_LR_WIDTH] SLB_R_,
	input wire [`DATA_WIDTH] SLB_s_vj_r1_,
	input wire [`DATA_WIDTH] SLB_s_vk_r1_,
	input wire [`DATA_WIDTH] SLB_s_qj_r1_,
	input wire [`DATA_WIDTH] SLB_s_qk_r1_,
	input wire [`DATA_WIDTH] SLB_s_inst_r1_,
	input wire [`DATA_WIDTH] SLB_s_ordertype_r1_,
	input wire [`DATA_WIDTH] SLB_s_pc_r1_,
	input wire [`DATA_WIDTH] SLB_s_A_r1_,
	input wire [`DATA_WIDTH] SLB_s_reorder_r1_,
	input wire SLB_s_ready_r1_,

	
	/* do_RS() */
	//RS
	input wire RS_to_SLB_needchange,
	input wire [`ROB_LR_WIDTH] b2,

	input wire [`DATA_WIDTH] RS_to_SLB_value,

	/* do_ROB() */
	//ROB
	input wire [`ROB_LR_WIDTH] b3,
	input wire ROB_to_SLB_needchange,
	input wire ROB_to_SLB_needchange2,
	input wire [`DATA_WIDTH] ROB_to_SLB_value_b3
);


// always @(*) begin
// 	$display("SLB        ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end

reg [`INST_TYPE_WIDTH] SLB_s_ordertype[`MaxSLB-1:0];
//reg [`DATA_WIDTH] SLB_s_inst[`MaxSLB-1:0];//for_debug
//reg [`DATA_WIDTH] SLB_s_pc[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_vj[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_vk[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_qj[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_qk[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_A[`MaxSLB-1:0];
reg [`DATA_WIDTH] SLB_s_reorder[`MaxSLB-1:0];
reg SLB_s_ready[`MaxSLB-1:0];
reg [`SLB_LR_WIDTH] SLB_L,SLB_R,SLB_size;
reg SLB_is_waiting_data;


//wire SLB_s_ready_L=SLB_s_ready[r3];//for_debug


wire [`DATA_WIDTH] loadvalue;

reg [`SLB_LR_WIDTH] r3;


Extend_LoadData u_Extend_LoadData(
    .tmp_ordertype ( SLB_s_ordertype[r3] ),
    .data          ( memctrl_data_ans          ),
    .ans           ( loadvalue           )
);

wire isload;
IsLoad u_IsLoad(
    .type ( SLB_s_ordertype[r3] ),
    .is_Load  ( isload  )
);


integer i;

reg insqueue_size_internal_subflag;

// do_SLB() part1
always @(*) begin
	insqueue_size_internal_subflag=0;

	SLB_to_memctrl_needchange=0;
	SLB_to_memctrl_needchange2=0;

	SLB_to_ROB_needchange=0;

	SLB_to_RS_needchange=0;
	
	b4=0;//for_latch
	r3=0;//for_latch
	SLB_to_memctrl_ordertype=0;//for_latch
	SLB_to_memctrl_vj=0;//for_latch
	SLB_to_memctrl_vk=0;//for_latch
	SLB_to_memctrl_A=0;//for_latch
	ROB_s_value_b4_=0;//for_latch
	ROB_s_ready_b4_=0;//for_latch
	SLB_to_RS_loadvalue=0;//for_latch


	if(memctrl_data_ok) begin
		r3=SLB_L;
		if(isload) begin
			// Extend_LoadData(SLB_s[r3];memctrl_data_ans;loadvalue);
			// update ROB
			b4=SLB_s_reorder[r3];
			SLB_to_ROB_needchange=1;
			ROB_s_value_b4_=loadvalue ; ROB_s_ready_b4_=1;

			// update RS
			SLB_to_RS_needchange=1;
			SLB_to_RS_loadvalue=loadvalue;
			// for(i=0;i<`MaxRS;i++) begin
			// 	if(RS_s_busy[i]) begin
			// 		if(RS_s_qj[i]==b4)RS_s_qj[i]=-1;RS_s_vj[i]=loadvalue;
			// 		if(RS_s_qk[i]==b4)RS_s_qk[i]=-1;RS_s_vk[i]=loadvalue;
			// 	end
			// end

			// update SLB
			insqueue_size_internal_subflag=1;

		end
		else  begin
			// update ROB
			b4=SLB_s_reorder[r3];
			SLB_to_ROB_needchange=1;
			ROB_s_ready_b4_=1;

			// update SLB
			insqueue_size_internal_subflag=1;
		end
	end

	if(!SLB_is_waiting_data&&SLB_size) begin
		r3=SLB_L;
		if(isload) begin
			if(SLB_s_qj[r3]==-1&&SLB_s_ready[r3]) begin
				SLB_to_memctrl_needchange=1;//load
				SLB_to_memctrl_ordertype=SLB_s_ordertype[r3];
				SLB_to_memctrl_vj=SLB_s_vj[r3];
				SLB_to_memctrl_A=SLB_s_A[r3];
				// LoadData(SLB_s[r3]);
			end
		end
		else  begin
			if(SLB_s_qj[r3]==-1&&SLB_s_qk[r3]==-1&&SLB_s_ready[r3]) begin
				SLB_to_memctrl_needchange2=1;//store
				SLB_to_memctrl_ordertype=SLB_s_ordertype[r3];
				SLB_to_memctrl_vj=SLB_s_vj[r3];
				SLB_to_memctrl_vk=SLB_s_vk[r3];
				SLB_to_memctrl_A=SLB_s_A[r3];
				// StoreData(SLB_s[r3]);
			end
		end
	end
end


always @(*) begin
	SLB_size__=SLB_size;
	SLB_R__=SLB_R;
end

always @(posedge clk) begin
	if(rst) begin
		// SLB
		for(i=0;i<`MaxSLB;i=i+1) begin
			SLB_s_ordertype[i]<=0;
//			SLB_s_inst[i]<=0;
//			SLB_s_pc[i]<=0;
			SLB_s_vj[i]<=0;
			SLB_s_vk[i]<=0;
			SLB_s_qj[i]<=-1;
			SLB_s_qk[i]<=-1;
			SLB_s_A[i]<=0;
			SLB_s_reorder[i]<=0;
			SLB_s_ready[i]<=0;
		end
		SLB_L<=1;SLB_R<=0;SLB_size<=0;
		SLB_is_waiting_data<=0;
	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		SLB_L<=1;SLB_R<=0;SLB_size<=0;SLB_is_waiting_data<=0;
		for(i=0;i<`MaxSLB;i=i+1) begin
			SLB_s_qj[i]<=-1;SLB_s_qk[i]<=-1;SLB_s_reorder[i]<=0;SLB_s_ready[i]<=0;
		end
	end
	else begin
		// for SLB_size
		SLB_size<=SLB_size+insqueue_to_SLB_size_addflag-insqueue_size_internal_subflag;

		// do_SLB() part2
		if(memctrl_data_ok) begin
			SLB_is_waiting_data<=0;
			if(isload) begin				
				// update SLB
				SLB_L<=(SLB_L+1)%`MaxSLB;
				SLB_s_qj[SLB_L]<=-1;SLB_s_qk[SLB_L]<=-1;
				for(i=0;i<`MaxSLB;i=i+1) begin
					if(SLB_s_qj[i]==b4) begin
						SLB_s_qj[i]<=-1;SLB_s_vj[i]<=loadvalue;
					end
					if(SLB_s_qk[i]==b4) begin
						SLB_s_qk[i]<=-1;SLB_s_vk[i]<=loadvalue;
					end
				end

			end
			else  begin
				// update SLB
				SLB_L<=(SLB_L+1)%`MaxSLB;
				SLB_s_qj[SLB_L]<=-1;SLB_s_qk[SLB_L]<=-1;
			end
		end

		if(!SLB_is_waiting_data&&SLB_size) begin
			if(isload) begin
				if(SLB_s_qj[r3]==-1&&SLB_s_ready[r3]) begin
					SLB_is_waiting_data<=1;
				end
			end
			else  begin
				if(SLB_s_qj[r3]==-1&&SLB_s_qk[r3]==-1&&SLB_s_ready[r3]) begin
					SLB_is_waiting_data<=1;
				end
			end
		end

		// from insqueue
		if(insqueue_to_SLB_needchange) begin
			SLB_R<=SLB_R_;
			SLB_s_vj[r1]<=SLB_s_vj_r1_;
			SLB_s_vk[r1]<=SLB_s_vk_r1_;
			SLB_s_qj[r1]<=SLB_s_qj_r1_;
			SLB_s_qk[r1]<=SLB_s_qk_r1_;
//			SLB_s_inst[r1]<=SLB_s_inst_r1_;
			SLB_s_ordertype[r1]<=SLB_s_ordertype_r1_;
//			SLB_s_pc[r1]<=SLB_s_pc_r1_;
			SLB_s_A[r1]<=SLB_s_A_r1_;
			SLB_s_reorder[r1]<=SLB_s_reorder_r1_;
			SLB_s_ready[r1]<=SLB_s_ready_r1_;
		end

		//from RS
		if(RS_to_SLB_needchange) begin
			for(i=0;i<`MaxSLB;i=i+1) begin
				if(SLB_s_qj[i]==b2) begin
					SLB_s_qj[i]<=-1;SLB_s_vj[i]<=RS_to_SLB_value;
				end
				if(SLB_s_qk[i]==b2) begin
					SLB_s_qk[i]<=-1;SLB_s_vk[i]<=RS_to_SLB_value;
				end
			end
		end

		// from ROB
		if(ROB_to_SLB_needchange) begin
			for(i=0;i<`MaxSLB;i=i+1) begin
				if(SLB_s_qj[i]==b3) begin
					SLB_s_qj[i]<=-1;SLB_s_vj[i]<=ROB_to_SLB_value_b3;
				end
				if(SLB_s_qk[i]==b3) begin
					SLB_s_qk[i]<=-1;SLB_s_vk[i]<=ROB_to_SLB_value_b3;
				end
			end
		end
		if(ROB_to_SLB_needchange2) begin
			for(i=0;i<`MaxSLB;i=i+1) begin
				if(SLB_s_reorder[i]==b3) begin
					SLB_s_ready[i]<=1;
				end
			end
		end
	end
end



endmodule