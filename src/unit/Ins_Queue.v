//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
 `include "info.v"

// `include "/RISCV-CPU/CPU/src/func/Decode.v"
// `include "/RISCV-CPU/CPU/src/func/IsBranch.v"
// `include "/RISCV-CPU/CPU/src/func/IsLoad.v"
// `include "/RISCV-CPU/CPU/src/func/IsStore.v"
module InstQueue (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* ClearAll */
	input wire Clear_flag,

	/* Get_ins_to_queue() */
	//memctrl
	input wire memctrl_ins_ok,
	input wire [`DATA_WIDTH] memctrl_ins_ans,

	output reg insqueue_to_memctrl_needchange,

	output reg [`DATA_WIDTH] memctrl_ins_addr_,
	output reg [3:0] memctrl_ins_remain_cycle_,

	//   Search_In_ICache()
	//icache
	output reg [`DATA_WIDTH] addr1,
	input wire hit_in,
	input wire [`DATA_WIDTH] returnInst,

	//   Store_In_ICache()
	//icache
	output reg insqueue_to_ICache_needchange,
	output reg [`DATA_WIDTH] addr2,
	output reg [`DATA_WIDTH] storeInst,

	//   BranchJudge()
	//BHT
	output reg [`BHT_LR_WIDTH] bht_id1,
	input wire bht_get,


	/* do_ins_queue() */
	//ROB
	output reg [`ROB_LR_WIDTH] h1,
	output reg [`ROB_LR_WIDTH] h2,

	input wire [`ROB_LR_WIDTH] ROB_size,
	input wire [`ROB_LR_WIDTH] ROB_R,
	input wire ROB_s_ready_h1,
	input wire [`DATA_WIDTH] ROB_s_value_h1,
	input wire ROB_s_ready_h2,
	input wire [`DATA_WIDTH] ROB_s_value_h2,

	output reg insqueue_to_ROB_needchange,
	output reg insqueue_to_ROB_size_addflag,
	output reg [`ROB_LR_WIDTH] b1,

	output reg [`ROB_LR_WIDTH] ROB_R_,
	output reg [`DATA_WIDTH] ROB_s_pc_b1_,
	output reg [`DATA_WIDTH] ROB_s_inst_b1_,
	output reg [`INST_TYPE_WIDTH] ROB_s_ordertype_b1_,
	output reg [`DATA_WIDTH] ROB_s_dest_b1_,
	output reg [`DATA_WIDTH] ROB_s_jumppc_b1_,
	output reg ROB_s_isjump_b1_,
	output reg ROB_s_ready_b1_,

	//RS
	input wire [`RS_LR_WIDTH] RS_unbusy_pos,

	output reg insqueue_to_RS_needchange,
	output reg [`RS_LR_WIDTH] r2,

	output reg [`DATA_WIDTH] RS_s_vj_r2_,
	output reg [`DATA_WIDTH] RS_s_vk_r2_,
	output reg [`DATA_WIDTH] RS_s_qj_r2_,
	output reg [`DATA_WIDTH] RS_s_qk_r2_,
	output reg [`DATA_WIDTH] RS_s_inst_r2_,
	output reg [`INST_TYPE_WIDTH] RS_s_ordertype_r2_,
	output reg [`DATA_WIDTH] RS_s_pc_r2_,
	output reg [`DATA_WIDTH] RS_s_jumppc_r2_,
	output reg [`DATA_WIDTH] RS_s_A_r2_,
	output reg [`DATA_WIDTH] RS_s_reorder_r2_,
	output reg RS_s_busy_r2_,

	//SLB
	input wire [`SLB_LR_WIDTH] SLB_size,
	input wire [`SLB_LR_WIDTH] SLB_R,

	output reg insqueue_to_SLB_needchange,
	output reg insqueue_to_SLB_size_addflag,
	output reg [`SLB_LR_WIDTH] r1,

	output reg [`SLB_LR_WIDTH] SLB_R_,
	output reg [`DATA_WIDTH] SLB_s_vj_r1_,
	output reg [`DATA_WIDTH] SLB_s_vk_r1_,
	output reg [`DATA_WIDTH] SLB_s_qj_r1_,
	output reg [`DATA_WIDTH] SLB_s_qk_r1_,
	output reg [`DATA_WIDTH] SLB_s_inst_r1_,
	output reg [`DATA_WIDTH] SLB_s_ordertype_r1_,
	output reg [`DATA_WIDTH] SLB_s_pc_r1_,
	output reg [`DATA_WIDTH] SLB_s_A_r1_,
	output reg [`DATA_WIDTH] SLB_s_reorder_r1_,
	output reg SLB_s_ready_r1_,

	//Reg
	output reg [`DATA_WIDTH] order_rs1,
	output reg [`DATA_WIDTH] order_rs2,

	input wire reg_busy_order_rs1,
	input wire reg_busy_order_rs2,
	input wire [`DATA_WIDTH] reg_reorder_order_rs1,
	input wire [`DATA_WIDTH] reg_reorder_order_rs2,
	input wire [`DATA_WIDTH] reg_reg_order_rs1,
	input wire [`DATA_WIDTH] reg_reg_order_rs2,
	
	output reg insqueue_to_Reg_needchange,
	output reg [`DATA_WIDTH] order_rd,

	output reg reg_busy_order_rd_,
	output reg [`DATA_WIDTH] reg_reorder_order_rd_,





	/* do_ROB() */
	//ROB
	input wire [`DATA_WIDTH] pc_ // Clear_flag=1ʱ�� (�������pc�����ȼ�����Get_ins_to_queue()�����ȼ� !!!)
);


// always @(*) begin
// 	$display("Ins_Queue  ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end

//pc
reg [`DATA_WIDTH] pc;

//Ins_queue
reg [`DATA_WIDTH] Ins_queue_s_inst[`MaxIns-1:0];
reg [`DATA_WIDTH] Ins_queue_s_pc[`MaxIns-1:0];
reg [`DATA_WIDTH] Ins_queue_s_jumppc[`MaxIns-1:0];
reg Ins_queue_s_isjump[`MaxIns-1:0];
reg [`INST_TYPE_WIDTH] Ins_queue_s_ordertype[`MaxIns-1:0];
reg [`INSQUEUE_LR_WIDTH] Ins_queue_L,Ins_queue_R,Ins_queue_size;
reg Ins_queue_is_waiting_ins;



//for Get_ins_to_queue()

reg hit;
reg [`DATA_WIDTH] inst;
wire [`INST_TYPE_WIDTH] order_type_0;
wire [`DATA_WIDTH] order_rd_0;
wire [`DATA_WIDTH] order_rs1_0;
wire [`DATA_WIDTH] order_rs2_0;
wire [`DATA_WIDTH] order_imm_0;

Decode u_Decode1(
    .inst ( inst ),
    .order_type ( order_type_0 ),
    .order_rd   ( order_rd_0   ),
    .order_rs1  ( order_rs1_0  ),
    .order_rs2  ( order_rs2_0  ),
    .order_imm  ( order_imm_0  )
);

wire isbranch;
IsBranch u_IsBranch(
    .type ( order_type_0 ),
    .is_Branch  ( isbranch  )
);


//for do_ins_queue()

wire [`INST_TYPE_WIDTH] order_type;
wire [`DATA_WIDTH] order_rd_;
wire [`DATA_WIDTH] order_rs1_;
wire [`DATA_WIDTH] order_rs2_;
wire [`DATA_WIDTH] order_imm;

//wire [31:0] order_inst=Ins_queue_s_inst[Ins_queue_L];//for_debug

Decode u_Decode2(
    .inst ( Ins_queue_s_inst[Ins_queue_L] ),
    .order_type ( order_type ),
    .order_rd   ( order_rd_   ),
    .order_rs1  ( order_rs1_  ),
    .order_rs2  ( order_rs2_  ),
    .order_imm  ( order_imm  )
);

always @(*) begin
	order_rd=order_rd_;
	order_rs1=order_rs1_;
	order_rs2=order_rs2_;
end

wire isload;
IsLoad u_IsLoad(
    .type ( Ins_queue_s_ordertype[Ins_queue_L] ),
    .is_Load  ( isload  )
);

wire isstore;
IsStore u_IsStore(
    .type ( Ins_queue_s_ordertype[Ins_queue_L] ),
    .is_Store  ( isstore  )
);

reg[31:0] insqueue_size_internal_addflag;

integer g;



integer i;


// Get_ins_to_queue() part1
always @(*) begin
	hit=0;
	insqueue_size_internal_addflag=0;

	insqueue_to_memctrl_needchange=0;
	insqueue_to_ICache_needchange=0;
	
	
	addr2=0;//for_latch
	memctrl_ins_addr_=0;//for_latch
	memctrl_ins_remain_cycle_=0;//for_latch
	storeInst=0;//for_latch
	bht_id1=0;//for_latch
    g=0;//for_latch

	if(!Ins_queue_is_waiting_ins&&Ins_queue_size!=`MaxIns) begin
		addr1=pc;
		hit=hit_in;
		// inst=returnInst; //do later(for_latch)
		// Search_In_ICache(pc;hit_in;inst);
		if(!hit) begin
			insqueue_to_memctrl_needchange=1;
			memctrl_ins_addr_=pc;
			memctrl_ins_remain_cycle_=4;
		end
	end
	else addr1=0;//for_latch

	if(memctrl_ins_ok) begin
		inst=memctrl_ins_ans;

		insqueue_to_ICache_needchange=1;
		addr2=pc;
		storeInst=memctrl_ins_ans;
		// Store_In_ICache(pc;memctrl_ins_ans);
	end
	else if(hit)inst=returnInst;
	else inst=0;//for_latch

	if(memctrl_ins_ok||hit) begin
		// Order order=Decode(inst);
		// if(order_type_0==`EEND) begin
		// end
		// else begin
			g=(Ins_queue_R+1)%`MaxIns;
			insqueue_size_internal_addflag=1;
			// Ins_queue_size++;

			// isBranch(order_type_0,isbranch);
			if(isbranch) begin
				//JAL ֱ����ת
				//Ŀǰǿ��pc����ת��JALRĬ�ϲ���ת�������ض�Ԥ��ʧ��
				if(order_type_0==`JAL);
				else  begin
					if(order_type_0==`JALR);
					else  begin
						bht_id1=inst[`BHT_LR_WIDTH];
						// BranchJudge(Ins_queue_s_inst[g][11:0]);
					end
				end
			end
		// end
	end
end

reg[31:0] insqueue_size_internal_subflag;

// do_ins_queue() part1
always @(*) begin
	insqueue_size_internal_subflag=0;
	
	insqueue_to_RS_needchange=0;

	insqueue_to_SLB_needchange=0;
	insqueue_to_SLB_size_addflag=0;

	insqueue_to_ROB_needchange=0;
	insqueue_to_ROB_size_addflag=0;
	
	insqueue_to_Reg_needchange=0;
	
	h1=0;//for_latch
	h2=0;//for_latch
	b1=0;//for_latch
	ROB_R_=0;//for_latch
	ROB_s_pc_b1_=0;//for_latch
	ROB_s_inst_b1_=0;//for_latch
	ROB_s_ordertype_b1_=0;//for_latch
	ROB_s_dest_b1_=0;//for_latch
	ROB_s_jumppc_b1_=0;//for_latch
	ROB_s_isjump_b1_=0;//for_latch
	ROB_s_ready_b1_=0;//for_latch
	r2=0;//for_latch
	RS_s_vj_r2_=0;//for_latch
	RS_s_vk_r2_=0;//for_latch
	RS_s_qj_r2_=0;//for_latch
	RS_s_qk_r2_=0;//for_latch
	RS_s_inst_r2_=0;//for_latch
	RS_s_ordertype_r2_=0;//for_latch
	RS_s_jumppc_r2_=0;//for_latch
	RS_s_pc_r2_=0;//for_latch
	RS_s_A_r2_=0;//for_latch
	RS_s_reorder_r2_=0;//for_latch
	RS_s_busy_r2_=0;//for_latch
	r1=0;//for_latch
	SLB_R_=0;//for_latch
	SLB_s_vj_r1_=0;//for_latch
	SLB_s_vk_r1_=0;//for_latch
	SLB_s_qj_r1_=0;//for_latch
	SLB_s_qk_r1_=0;//for_latch
	SLB_s_inst_r1_=0;//for_latch
	SLB_s_ordertype_r1_=0;//for_latch
	SLB_s_pc_r1_=0;//for_latch
	SLB_s_A_r1_=0;//for_latch
	SLB_s_reorder_r1_=0;//for_latch
	SLB_s_ready_r1_=0;//for_latch
	reg_busy_order_rd_=0;//for_latch
	reg_reorder_order_rd_=0;//for_latch
	
	

	//InstructionQueueΪ�գ����ȡ��issue InstructionQueue�е�ָ��
	if(Ins_queue_size==0);
	//ROB���ˣ����ȡ��issue InstructionQueue�е�ָ��
	else if(ROB_size==`MaxROB);
	else begin
		// isLoad(Ins_queue_s_ordertype,isload[Ins_queue_L]);
		// isStore(Ins_queue_s_ordertype,isstore[Ins_queue_L]);
		if(isload||isstore) begin //loadָ��(LB;LH;LW;LBU;LHU) or storeָ��(SB;SH;SW)
			
			//SLB���ˣ����ȡ��issue InstructionQueue�е�ָ��
			if(SLB_size==`MaxSLB);
			else begin
				insqueue_to_SLB_needchange=1;
				insqueue_to_ROB_needchange=1;
				//rΪ��ָ��SLB׼����ŵ�λ??
				r1=(SLB_R+1)%`MaxSLB;
				SLB_R_=r1;insqueue_to_SLB_size_addflag=1;
				
				//bΪ��ָ��ROB׼����ŵ�λ??
				b1=(ROB_R+1)%`MaxROB;
				ROB_R_=b1;insqueue_to_ROB_size_addflag=1;

				//����ָ���Ins_queueɾȥ
				insqueue_size_internal_subflag=1;
				// Ins_queue_size--;
				//����
				// Order order=Decode(Ins_queue_s_inst[Ins_queue_L]);
				
				//�޸�ROB
				ROB_s_pc_b1_=Ins_queue_s_pc[Ins_queue_L];
				ROB_s_inst_b1_=Ins_queue_s_inst[Ins_queue_L]; ROB_s_ordertype_b1_=Ins_queue_s_ordertype[Ins_queue_L];
				ROB_s_dest_b1_=order_rd ; ROB_s_ready_b1_=0;
				
				//�޸�SLB


				//����rs1�Ĵ�������������Ƿ����renaming(vj;qj)
				//���rs1�Ĵ�����Ϊbusy����??��һ���޸Ķ�Ӧ��ROBλ�û�δcommit����renaming
				if(reg_busy_order_rs1) begin
					h1=reg_reorder_order_rs1;
					if(ROB_s_ready_h1) begin
						SLB_s_vj_r1_=ROB_s_value_h1;SLB_s_qj_r1_=-1;
					end
					else SLB_s_qj_r1_=h1;
				end
				else begin
					SLB_s_vj_r1_=reg_reg_order_rs1;SLB_s_qj_r1_=-1;
				end

				if(isstore) begin// store����  ����rs2�ģ�
					//����rs2�Ĵ�������������Ƿ����renaming(vk;qk)
					//���rs2�Ĵ�����Ϊbusy����??��һ���޸Ķ�Ӧ��ROBλ�û�δcommit����renaming
					if(reg_busy_order_rs2) begin
						h2=reg_reorder_order_rs2;
						if(ROB_s_ready_h2) begin
							SLB_s_vk_r1_=ROB_s_value_h2;SLB_s_qk_r1_=-1;
						end
						else SLB_s_qk_r1_=h2;
					end
					else begin
						SLB_s_vk_r1_=reg_reg_order_rs2;SLB_s_qk_r1_=-1;
					end
				end
				else SLB_s_qk_r1_=-1;
				
				SLB_s_inst_r1_=Ins_queue_s_inst[Ins_queue_L] ; SLB_s_ordertype_r1_=Ins_queue_s_ordertype[Ins_queue_L];
				SLB_s_pc_r1_=Ins_queue_s_pc[Ins_queue_L];
				SLB_s_A_r1_=order_imm ; SLB_s_reorder_r1_=b1;
				
				if(isstore)SLB_s_ready_r1_=0;

				//�޸�register
				if(!isstore) begin//��Ϊ storeָ��  (��������rd)
					insqueue_to_Reg_needchange=1;
					reg_reorder_order_rd_=b1;reg_busy_order_rd_=1;
				end
			end
		end
		else begin// ����(LUI;AUIPC;ADD;SUB___) or ��������??(BEQ;BNE;BLE___) or ��������??(JAL;JALR)
			
			//�ҵ�??���յ�RS��λ�ã�rΪ�ҵ��Ŀյ�RS��λ??
			r2=RS_unbusy_pos; //�Ҳ�����??-1
			// r2=-1;
			// for(i=0;i<`MaxRS;i++) begin
			// 	if(!RS_s_busy[i]) begin
			// 		r2=i;break;
			// 	end
			// end
			//RS���ˣ����ȡ��issue InstructionQueue�е�ָ��
			if(r2==-1);
			else begin
				//bΪ��ָ��ROB׼����ŵ�λ??
				b1=(ROB_R+1)%`MaxROB;
				//����ָ���Ins_queueɾȥ
				insqueue_size_internal_subflag=1;
				// Ins_queue_size--;
				//����
				// Order order=Decode(Ins_queue_s_inst[Ins_queue_L]);

				//�޸�ROB
				insqueue_to_ROB_needchange=1;
				ROB_R_=b1;insqueue_to_ROB_size_addflag=1;
				ROB_s_inst_b1_=Ins_queue_s_inst[Ins_queue_L]; ROB_s_ordertype_b1_=Ins_queue_s_ordertype[Ins_queue_L];
				ROB_s_pc_b1_=Ins_queue_s_pc[Ins_queue_L]; ROB_s_jumppc_b1_=Ins_queue_s_jumppc[Ins_queue_L] ; ROB_s_isjump_b1_=Ins_queue_s_isjump[Ins_queue_L];
				ROB_s_dest_b1_=order_rd ; ROB_s_ready_b1_=0;

				//�޸�RS
				insqueue_to_RS_needchange=1;
				if( Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h37&&Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h17 && Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h6f ) begin// ��ΪLUI;AUIPC;JAL (��rs1??)
					//����rs1�Ĵ�������������Ƿ����renaming(vj;qj)
					//���rs1�Ĵ�����Ϊbusy����??��һ���޸Ķ�Ӧ��ROBλ�û�δcommit����renaming
					if(reg_busy_order_rs1) begin
						h1=reg_reorder_order_rs1;
						if(ROB_s_ready_h1) begin
							RS_s_vj_r2_=ROB_s_value_h1;RS_s_qj_r2_=-1;
						end
						else RS_s_qj_r2_=h1;
					end
					else begin
						RS_s_vj_r2_=reg_reg_order_rs1;RS_s_qj_r2_=-1;
					end
				end
				else RS_s_qj_r2_=-1;

				if( Ins_queue_s_inst[Ins_queue_L][6:0]==7'h33 || Ins_queue_s_inst[Ins_queue_L][6:0]==7'h63) begin// (ADD__AND) or ��������??  ����rs2�ģ�
					//����rs2�Ĵ�������������Ƿ����renaming(vk;qk)
					//���rs2�Ĵ�����Ϊbusy����??��һ���޸Ķ�Ӧ��ROBλ�û�δcommit����renaming
					if(reg_busy_order_rs2) begin
						h2=reg_reorder_order_rs2;
						if(ROB_s_ready_h2) begin
							RS_s_vk_r2_=ROB_s_value_h2;RS_s_qk_r2_=-1;
						end
						else RS_s_qk_r2_=h2;
					end
					else begin 
						RS_s_vk_r2_=reg_reg_order_rs2;RS_s_qk_r2_=-1;
					end
				end
				else RS_s_qk_r2_=-1;
				

				RS_s_inst_r2_=Ins_queue_s_inst[Ins_queue_L] ; RS_s_ordertype_r2_=Ins_queue_s_ordertype[Ins_queue_L];
				RS_s_pc_r2_=Ins_queue_s_pc[Ins_queue_L] ; RS_s_jumppc_r2_=Ins_queue_s_jumppc[Ins_queue_L];
				RS_s_A_r2_=order_imm ; RS_s_reorder_r2_=b1;
				RS_s_busy_r2_=1;

				//�޸�register
				if(Ins_queue_s_inst[Ins_queue_L][6:0]!=7'h63) begin//��Ϊ ��������??  (��������rd)
					insqueue_to_Reg_needchange=1;
					reg_reorder_order_rd_=b1;reg_busy_order_rd_=1;
				end
			end
		end
	end
end





always @(posedge clk) begin
	if(rst) begin
		//pc
		pc<=0;

		//Ins_queue
		for(i=0;i<`MaxIns;i=i+1) begin
			Ins_queue_s_inst[i]<=0;
			Ins_queue_s_pc[i]<=0;
			Ins_queue_s_jumppc[i]<=0;
			Ins_queue_s_isjump[i]<=0;
			Ins_queue_s_ordertype[i]<=0;
		end
		Ins_queue_L<=1;Ins_queue_R<=0;Ins_queue_size<=0;
		Ins_queue_is_waiting_ins<=0;

	end
	else if(~rdy) begin
	end
	else if(Clear_flag) begin
		Ins_queue_L<=1;Ins_queue_R<=0;Ins_queue_size<=0;Ins_queue_is_waiting_ins<=0;
		pc<=pc_;
	end
	else begin
		//for Ins_queue_size
		Ins_queue_size<=Ins_queue_size+insqueue_size_internal_addflag-insqueue_size_internal_subflag;

		// Get_ins_to_queue() part2
		if(!Ins_queue_is_waiting_ins&&Ins_queue_size!=`MaxIns) begin
			if(!hit) begin
				Ins_queue_is_waiting_ins<=1;
			end
		end
		if(memctrl_ins_ok) begin
			Ins_queue_is_waiting_ins<=0;
		end
		if(memctrl_ins_ok||hit) begin
			Ins_queue_R<=g;

			Ins_queue_s_inst[g]<=inst;Ins_queue_s_ordertype[g]<=order_type_0;Ins_queue_s_pc[g]<=pc;
			if(isbranch) begin
				//JAL ֱ����ת
				//Ŀǰǿ��pc����ת��JALRĬ�ϲ���ת�������ض�Ԥ��ʧ��
				if(order_type_0==`JAL) begin
					pc<=pc+order_imm_0;
				end
				else  begin
					if(order_type_0==`JALR) begin
						pc<=pc+4;
					end
					else  begin
						Ins_queue_s_jumppc[g]<=pc+order_imm_0;
						if(bht_get) begin
							pc<=pc+order_imm_0;
							Ins_queue_s_isjump[g]<=1;
						end
						else begin
							pc<=pc+4;
							Ins_queue_s_isjump[g]<=0;
						end
					end
				end
			end
			else begin
				pc<=pc+4;
			end
		end

		// do_ins_queue() part2
		
		//InstructionQueueΪ�գ����ȡ��issue InstructionQueue�е�ָ��
		if(Ins_queue_size==0);
		//ROB���ˣ����ȡ��issue InstructionQueue�е�ָ��
		else if(ROB_size==`MaxROB);
		else begin
			if(isload||isstore) begin //loadָ��(LB;LH;LW;LBU;LHU) or storeָ��(SB;SH;SW)
				//SLB���ˣ����ȡ��issue InstructionQueue�е�ָ��
				if(SLB_size==`MaxSLB);
				else begin
					//����ָ���Ins_queueɾȥ
					Ins_queue_L<=(Ins_queue_L+1)%`MaxIns;
				end
			end
			else begin// ����(LUI;AUIPC;ADD;SUB___) or ��������??(BEQ;BNE;BLE___) or ��������??(JAL;JALR)
				if(r2==-1);
				else begin
					//����ָ���Ins_queueɾȥ
					Ins_queue_L<=(Ins_queue_L+1)%`MaxIns;
				end
			end
		end
	end
end

endmodule