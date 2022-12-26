//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "E://RISCV-CPU/CPU/src/info.v"

// `include "/RISCV-CPU/CPU/src/func/IsBranch.v"
// `include "/RISCV-CPU/CPU/src/func/IsStore.v"
module ROB (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* do_ROB() */
	//RS and SLB
	output reg [`ROB_LR_WIDTH] b3,
	
	//BHT
	output reg ROB_to_BHT_needchange, // predict wrong
	output reg ROB_to_BHT_needchange2, // predict correct
	output reg [`BHT_LR_WIDTH] bht_id2,

	//RS
	output reg ROB_to_RS_needchange,
	output reg [`DATA_WIDTH] ROB_to_RS_value_b3,

	//SLB
	output reg ROB_to_SLB_needchange,
	output reg ROB_to_SLB_needchange2,
	output reg [`DATA_WIDTH] ROB_to_SLB_value_b3,


	//Reg
	output reg [`DATA_WIDTH] commit_rd,

	input wire reg_busy_commit_rd,
	input wire [`ROB_LR_WIDTH] reg_reorder_commit_rd,
	
	output reg ROB_to_Reg_needchange,
	output reg ROB_to_Reg_needchange2,
	
	output reg [`DATA_WIDTH] reg_reg_commit_rd_,
	output reg reg_busy_commit_rd_,

	//insqueue
	output reg [`DATA_WIDTH] pc_,// Clear_flag=1时做 (这个更改pc的优先级高于Get_ins_to_queue()的优先级 !!!)

	//Clear_flag (cpu.v)
	output reg Clear_flag_,



	/* do_ins_queue() */
	//insqueue
	input wire [`ROB_LR_WIDTH] h1,
	input wire [`ROB_LR_WIDTH] h2,

	output reg [`ROB_LR_WIDTH] ROB_size__,
	output reg [`ROB_LR_WIDTH] ROB_R__,
	output reg ROB_s_ready_h1,
	output reg [`DATA_WIDTH] ROB_s_value_h1,
	output reg ROB_s_ready_h2,
	output reg [`DATA_WIDTH] ROB_s_value_h2,

	input wire insqueue_to_ROB_needchange,
	input wire insqueue_to_ROB_size_addflag,
	input wire [`ROB_LR_WIDTH] b1,

	input wire [`ROB_LR_WIDTH] ROB_R_,
	input wire [`DATA_WIDTH] ROB_s_pc_b1_,
	input wire [`DATA_WIDTH] ROB_s_inst_b1_,
	input wire [`INST_TYPE_WIDTH] ROB_s_ordertype_b1_,
	input wire [`DATA_WIDTH] ROB_s_dest_b1_,
	input wire [`DATA_WIDTH] ROB_s_jumppc_b1_,
	input wire ROB_s_isjump_b1_,
	input wire ROB_s_ready_b1_,

	/* do_RS() */
	//RS
	input wire RS_to_ROB_needchange,
	input wire RS_to_ROB_needchange2,
	input wire [`ROB_LR_WIDTH] b2,

	input wire [`DATA_WIDTH] ROB_s_value_b2_,
	input wire ROB_s_ready_b2_,
	input wire [`DATA_WIDTH] ROB_s_jumppc_b2_,

	/* do_SLB() */
	//SLB
	input wire SLB_to_ROB_needchange,
	input wire [`ROB_LR_WIDTH] b4,

	input wire [`DATA_WIDTH] ROB_s_value_b4_,
	input wire ROB_s_ready_b4_
);


// always @(*) begin
// 	$display("ROB        ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end

reg [`INST_TYPE_WIDTH] ROB_s_ordertype[`MaxROB-1:0];
reg [`DATA_WIDTH] ROB_s_inst[`MaxROB-1:0];
reg [`DATA_WIDTH] ROB_s_pc[`MaxROB-1:0];
reg [`DATA_WIDTH] ROB_s_jumppc[`MaxROB-1:0];
reg [`DATA_WIDTH] ROB_s_dest[`MaxROB-1:0];
reg [`DATA_WIDTH] ROB_s_value[`MaxROB-1:0];
reg ROB_s_isjump[`MaxROB-1:0];
reg ROB_s_ready[`MaxROB-1:0];
reg [`ROB_LR_WIDTH] ROB_L,ROB_R,ROB_size;


reg ROB_size_internal_subflag;



wire isbranch;
IsBranch u_IsBranch(
    .type ( ROB_s_ordertype[b3] ),
    .is_Branch  ( isbranch  )
);

wire isstore;
IsStore u_IsStore(
    .type ( ROB_s_ordertype[b3] ),
    .is_Store  ( isstore  )
);

wire isload;
IsLoad u_IsLoad(
    .type ( ROB_s_ordertype[b3] ),
    .is_Load  ( isload  )
);

integer i;

wire ROB_s_ready_L=ROB_s_ready[b3];//for_debug
wire[31:0] ROB_s_value_L=ROB_s_value[b3];//for_debug
wire [`INST_TYPE_WIDTH] ROB_s_ordertype_L=ROB_s_ordertype[b3];//for_debug
wire[31:0] ROB_s_jumppc_L=ROB_s_jumppc[b3];//for_debug

// do_ROB() part1
always @(*) begin
	ROB_size_internal_subflag=0;

	ROB_to_Reg_needchange=0;
	ROB_to_Reg_needchange2=0;
	
	ROB_to_RS_needchange=0;
	
	ROB_to_SLB_needchange=0;
	ROB_to_SLB_needchange2=0;
	
	ROB_to_BHT_needchange=0;
	ROB_to_BHT_needchange2=0;
		
	Clear_flag_=0;
	
	b3=0;//for_latch
	bht_id2=0;//for_latch
	ROB_to_RS_value_b3=0;//for_latch
	ROB_to_SLB_value_b3=0;//for_latch
	commit_rd=0;//for_latch
	reg_reg_commit_rd_=0;//for_latch
	reg_busy_commit_rd_=0;//for_latch
	pc_=0;//for_latch

	if(!ROB_size);
	else begin
		b3=ROB_L;
		if(isbranch) begin
			if(!ROB_s_ready[b3]);
			else begin
				// update ROB
				ROB_size_internal_subflag=1;

				//JAL必定预测成功
				//让JALR必定预测失败
				if(ROB_s_ordertype[b3]==`JAL) begin

					// update register
					ROB_to_Reg_needchange=1;
					commit_rd=ROB_s_dest[b3];
					reg_reg_commit_rd_=ROB_s_value[b3];
					if(reg_busy_commit_rd&&reg_reorder_commit_rd==b3) begin 
						ROB_to_Reg_needchange2=1;
						reg_busy_commit_rd_=0;
					end
					
					// update RS
					ROB_to_RS_needchange=1;
					ROB_to_RS_value_b3=ROB_s_value[b3];
					// for(i=0;i<`MaxRS;i++) begin
					// 	if(RS_s_busy[i]) begin
					// 		if(RS_s_qj[i]==b3) begin
					// 			RS_s_qj[i]=-1;RS_s_vj[i]=ROB_s_value[b3];
					// 		end
					// 		if(RS_s_qk[i]==b3) begin
					// 			RS_s_qk[i]=-1;RS_s_vk[i]=ROB_s_value[b3];
					// 		end
					// 	end
					// end

					// update SLB
					ROB_to_SLB_needchange=1;
					ROB_to_SLB_value_b3=ROB_s_value[b3];
					// for(i=0;i<`MaxSLB;i++) begin
					// 	if(SLB_s_qj[i]==b3) begin
					// 		SLB_s_qj[i]=-1;SLB_s_vj[i]=ROB_s_value[b3];
					// 	end
					// 	if(SLB_s_qk[i]==b3) begin
					// 		SLB_s_qk[i]=-1;SLB_s_vk[i]=ROB_s_value[b3];
					// 	end
					// end
				end
				else begin

					if( (ROB_s_value[b3]^ROB_s_isjump[b3])==1 || ROB_s_ordertype[b3]==`JALR) begin//预测失败

						// update BHT
						ROB_to_BHT_needchange=1;
						bht_id2=ROB_s_inst[b3][`BHT_LR_WIDTH];
						// if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
						// 	BHT_s[bht_id2][0]=0;BHT_s[bht_id2][1]=1;
						// end
						// if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
						// 	BHT_s[bht_id2][0]=1;BHT_s[bht_id2][1]=0;
						// end
						// if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
						// 	BHT_s[bht_id2][0]=0;BHT_s[bht_id2][1]=1;
						// end
						// if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
						// 	BHT_s[bht_id2][0]=1;BHT_s[bht_id2][1]=0;
						// end

						// update pc
						if(ROB_s_value[b3])pc_=ROB_s_jumppc[b3];
						else pc_=ROB_s_pc[b3]+4;
						
						// update Clear_flag
						Clear_flag_=1;

						if(ROB_s_ordertype[b3]==`JALR) begin
							// update register
							ROB_to_Reg_needchange=1;
							commit_rd=ROB_s_dest[b3];
							reg_reg_commit_rd_=ROB_s_value[b3];
							if(reg_busy_commit_rd&&reg_reorder_commit_rd==b3) begin
								ROB_to_Reg_needchange2=1;
								reg_busy_commit_rd_=0;
							end
						end
					end
					else begin//预测成功
						// update BHT
						ROB_to_BHT_needchange2=1;
						bht_id2=ROB_s_inst[b3][`BHT_LR_WIDTH];
						// if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
						// 	BHT_s[bht_id2][0]=0;BHT_s[bht_id2][1]=0;
						// end
						// if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
						// 	BHT_s[bht_id2][0]=0;BHT_s[bht_id2][1]=0;
						// end
						// if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
						// 	BHT_s[bht_id2][0]=1;BHT_s[bht_id2][1]=1;
						// end
						// if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
						// 	BHT_s[bht_id2][0]=1;BHT_s[bht_id2][1]=1;
						// end
					end
				end
			end
		end
		else if(isstore) begin
			if(!ROB_s_ready[b3]) begin
				// update SLB
				ROB_to_SLB_needchange2=1;
				// for(i=0;i<`MaxSLB;i++) begin
				// 	if(SLB_s_reorder[i]==b3) begin
				// 		SLB_s_ready[i]=1;
				// 	end
				// end
			end
			else begin
				// update ROB
				ROB_size_internal_subflag=1;
			end
		end
		else begin//Load or calc
		    if(isload&&!ROB_s_ready[b3]) begin
                ROB_to_SLB_needchange2=1;
            end
            else begin
                if(!ROB_s_ready[b3]);
                else begin
                    // update ROB
                    ROB_size_internal_subflag=1;
    
                    // update register
                    ROB_to_Reg_needchange=1;
                    commit_rd=ROB_s_dest[b3];
                    reg_reg_commit_rd_=ROB_s_value[b3];
                    if(reg_busy_commit_rd&&reg_reorder_commit_rd==b3) begin
                        ROB_to_Reg_needchange2=1;
                        reg_busy_commit_rd_=0;
                    end
    
                    // update RS
                    ROB_to_RS_needchange=1;
                    ROB_to_RS_value_b3=ROB_s_value[b3];
                    // for(i=0;i<`MaxRS;i++) begin
                    // 	if(RS_s_busy[i]) begin
                    // 		if(RS_s_qj[i]==b3) begin
                    // 			RS_s_qj[i]=-1;RS_s_vj[i]=ROB_s_value[b3];
                    // 		end
                    // 		if(RS_s_qk[i]==b3) begin
                    // 			RS_s_qk[i]=-1;RS_s_vk[i]=ROB_s_value[b3];
                    // 		end
                    // 	end
                    // end
    
                    // update SLB
                    ROB_to_SLB_needchange=1;
                    ROB_to_SLB_value_b3=ROB_s_value[b3];
                    // for(i=0;i<`MaxSLB;i++) begin
                    // 	if(SLB_s_qj[i]==b3) begin
                    // 		SLB_s_qj[i]=-1;SLB_s_vj[i]=ROB_s_value[b3];
                    // 	end
                    // 	if(SLB_s_qk[i]==b3) begin
                    // 		SLB_s_qk[i]=-1;SLB_s_vk[i]=ROB_s_value[b3];
                    // 	end
                    // end
                end
            end
		end
	end
end



always @(*) begin
	ROB_size__=ROB_size;
	ROB_R__=ROB_R;
	ROB_s_ready_h1=ROB_s_ready[h1];
	ROB_s_value_h1=ROB_s_value[h1];
	ROB_s_ready_h2=ROB_s_ready[h2];
	ROB_s_value_h2=ROB_s_value[h2];
end

always @(posedge clk) begin
	if(rst) begin
		// ROB
		for(i=0;i<`MaxROB;i=i+1) begin
			ROB_s_ordertype[i]<=0;
			ROB_s_inst[i]<=0;
			ROB_s_pc[i]<=0;
			ROB_s_jumppc[i]<=0;
			ROB_s_dest[i]<=0;
			ROB_s_value[i]<=0;
			ROB_s_isjump[i]<=0;
			ROB_s_ready[i]<=0;
		end
		ROB_L<=1;ROB_R<=0;ROB_size<=0;

	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		ROB_L<=1;ROB_R<=0;ROB_size<=0;
		for(i=0;i<`MaxROB;i=i+1)ROB_s_ready[i]<=0;
	end
	else begin
		// for ROB_size
		ROB_size<=ROB_size+insqueue_to_ROB_size_addflag-ROB_size_internal_subflag;

		// do_ROB() part2
		if(!ROB_size);
		else begin
			if(isbranch) begin
				if(!ROB_s_ready[b3]);
				else begin
					// update ROB
					ROB_L<=(ROB_L+1)%`MaxROB;
				end
			end
			else if(isstore) begin
				if(!ROB_s_ready[b3]);
				else begin
					// update ROB
					ROB_L<=(ROB_L+1)%`MaxROB;
				end
			end
			else begin//Load or calc
			    if(isload&&!ROB_s_ready[b3]);
                else begin
                    if(!ROB_s_ready[b3]);
                    else begin
                        // update ROB
                        ROB_L<=(ROB_L+1)%`MaxROB;
                    end
                end
			end
		end



		// from insqueue
		if(insqueue_to_ROB_needchange) begin
			ROB_R<=ROB_R_;
			ROB_s_pc[b1]<=ROB_s_pc_b1_;
			ROB_s_inst[b1]<=ROB_s_inst_b1_;
			ROB_s_ordertype[b1]<=ROB_s_ordertype_b1_;
			ROB_s_dest[b1]<=ROB_s_dest_b1_;
			ROB_s_jumppc[b1]<=ROB_s_jumppc_b1_;
			ROB_s_isjump[b1]<=ROB_s_isjump_b1_;
			ROB_s_ready[b1]<=ROB_s_ready_b1_;		
		end

		//from RS
		if(RS_to_ROB_needchange) begin
			ROB_s_value[b2]<=ROB_s_value_b2_;
			ROB_s_ready[b2]<=ROB_s_ready_b2_;
			if(RS_to_ROB_needchange2) begin
				ROB_s_jumppc[b2]<=ROB_s_jumppc_b2_;
			end
		end
		
		if(SLB_to_ROB_needchange) begin
			ROB_s_value[b4]<=ROB_s_value_b4_;
			ROB_s_ready[b4]<=ROB_s_ready_b4_;
		end
	end

end



endmodule