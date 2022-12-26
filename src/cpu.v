// RISCV32I CPU top module
// port modification allowed for debugging purposes

//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/BHT.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/ICache.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/Ins_Queue.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/MemCtrl.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/Reg.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/ROB.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/RS.v"
//`include "/mnt/e/RISCV-CPU/CPU/src/unit/SLB.v"

// `include "/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/unit/BHT.v"
// `include "/RISCV-CPU/CPU/src/unit/ICache.v"
// `include "/RISCV-CPU/CPU/src/unit/Ins_Queue.v"
// `include "/RISCV-CPU/CPU/src/unit/MemCtrl.v"
// `include "/RISCV-CPU/CPU/src/unit/Reg.v"
// `include "/RISCV-CPU/CPU/src/unit/ROB.v"
// `include "/RISCV-CPU/CPU/src/unit/RS.v"
// `include "/RISCV-CPU/CPU/src/unit/SLB.v"


 `include "info.v"
//  `include "unit/BHT.v"
//  `include "unit/ICache.v"
//  `include "unit/Ins_Queue.v"
//  `include "unit/MemCtrl.v"
//  `include "unit/Reg.v"
//  `include "unit/ROB.v"
//  `include "unit/RS.v"
//  `include "unit/SLB.v"


module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
  input  wire			      rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,	    	// data input bus
  output wire [ 7:0]          mem_dout,		    // data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
  input  wire                 io_buffer_full,   // 1 if uart buffer is full
	
  output wire [31:0]	      dbgreg_dout       // cpu register output (debugging demo)
);
// always @(*) begin
// 	$display("cpu        ","clk=",clk_in,",rst=",rst_in,", time=%t",$realtime);
// end

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire Clear_flag;

/* Get_ins_to_queue() */  //insqueue
//memctrl
wire memctrl_ins_ok;
wire [`DATA_WIDTH] memctrl_ins_ans;

wire insqueue_to_memctrl_needchange;

wire [`DATA_WIDTH] memctrl_ins_addr_;
wire [3:0] memctrl_ins_remain_cycle_;

//   Search_In_ICache()
//icache
wire [`DATA_WIDTH] addr1;
wire hit;
wire [`DATA_WIDTH] returnInst;

//   Store_In_ICache()
//icache
wire insqueue_to_ICache_needchange;
wire [`DATA_WIDTH] addr2;
wire [`DATA_WIDTH] storeInst;

//   BranchJudge()
//BHT
wire [`BHT_LR_WIDTH] bht_id1;
wire bht_get;


/* do_ins_queue() */  //insqueue
//ROB
wire [`ROB_LR_WIDTH] h1;
wire [`ROB_LR_WIDTH] h2;

wire [`ROB_LR_WIDTH] ROB_size;
wire [`ROB_LR_WIDTH] ROB_R;
wire ROB_s_ready_h1;
wire [`DATA_WIDTH] ROB_s_value_h1;
wire ROB_s_ready_h2;
wire [`DATA_WIDTH] ROB_s_value_h2;

wire insqueue_to_ROB_needchange;
wire insqueue_to_ROB_size_addflag;
wire [`ROB_LR_WIDTH] b1;

wire [`ROB_LR_WIDTH] ROB_R_;
wire [`DATA_WIDTH] ROB_s_pc_b1_;
wire [`DATA_WIDTH] ROB_s_inst_b1_;
wire [`INST_TYPE_WIDTH] ROB_s_ordertype_b1_;
wire [`DATA_WIDTH] ROB_s_dest_b1_;
wire [`DATA_WIDTH] ROB_s_jumppc_b1_;
wire ROB_s_isjump_b1_;
wire ROB_s_ready_b1_;

//RS
wire [`RS_LR_WIDTH] RS_unbusy_pos;

wire insqueue_to_RS_needchange;
wire [`RS_LR_WIDTH] r2;

wire [`DATA_WIDTH] RS_s_vj_r2_;
wire [`DATA_WIDTH] RS_s_vk_r2_;
wire [`DATA_WIDTH] RS_s_qj_r2_;
wire [`DATA_WIDTH] RS_s_qk_r2_;
wire [`DATA_WIDTH] RS_s_inst_r2_;
wire [`INST_TYPE_WIDTH] RS_s_ordertype_r2_;
wire [`DATA_WIDTH] RS_s_pc_r2_;
wire [`DATA_WIDTH] RS_s_jumppc_r2_;
wire [`DATA_WIDTH] RS_s_A_r2_;
wire [`DATA_WIDTH] RS_s_reorder_r2_;
wire RS_s_busy_r2_;

//SLB
wire [`SLB_LR_WIDTH] SLB_size;
wire [`SLB_LR_WIDTH] SLB_R;

wire insqueue_to_SLB_needchange;
wire insqueue_to_SLB_size_addflag;
wire [`SLB_LR_WIDTH] r1;

wire [`SLB_LR_WIDTH] SLB_R_;
wire [`DATA_WIDTH] SLB_s_vj_r1_;
wire [`DATA_WIDTH] SLB_s_vk_r1_;
wire [`DATA_WIDTH] SLB_s_qj_r1_;
wire [`DATA_WIDTH] SLB_s_qk_r1_;
wire [`DATA_WIDTH] SLB_s_inst_r1_;
wire [`DATA_WIDTH] SLB_s_ordertype_r1_;
wire [`DATA_WIDTH] SLB_s_pc_r1_;
wire [`DATA_WIDTH] SLB_s_A_r1_;
wire [`DATA_WIDTH] SLB_s_reorder_r1_;
wire SLB_s_ready_r1_;

//Reg
wire [`DATA_WIDTH] order_rs1;
wire [`DATA_WIDTH] order_rs2;

wire reg_busy_order_rs1;
wire reg_busy_order_rs2;
wire [`DATA_WIDTH] reg_reorder_order_rs1;
wire [`DATA_WIDTH] reg_reorder_order_rs2;
wire [`DATA_WIDTH] reg_reg_order_rs1;
wire [`DATA_WIDTH] reg_reg_order_rs2;

wire insqueue_to_Reg_needchange;
wire [`DATA_WIDTH] order_rd;

wire reg_busy_order_rd_;
wire [`DATA_WIDTH] reg_reorder_order_rd_;


/* do_ROB() */  //ROB
//RS and SLB
wire [`ROB_LR_WIDTH] b3;

//BHT
wire ROB_to_BHT_needchange; // predict wrong
wire ROB_to_BHT_needchange2; // predict correct
wire [`BHT_LR_WIDTH] bht_id2;

//RS
wire ROB_to_RS_needchange;
wire [`DATA_WIDTH] ROB_to_RS_value_b3;

//SLB
wire ROB_to_SLB_needchange;
wire ROB_to_SLB_needchange2;
wire [`DATA_WIDTH] ROB_to_SLB_value_b3;


//Reg
wire [`DATA_WIDTH] commit_rd;

wire reg_busy_commit_rd;
wire [`ROB_LR_WIDTH] reg_reorder_commit_rd;

wire ROB_to_Reg_needchange;
wire ROB_to_Reg_needchange2;

wire [`DATA_WIDTH] reg_reg_commit_rd_;
wire reg_busy_commit_rd_;

//insqueue
wire [`DATA_WIDTH] pc_;

/* do_RS() */  //RS
//ROB and SLB
wire [`ROB_LR_WIDTH] b2;

//ROB
wire RS_to_ROB_needchange;
wire RS_to_ROB_needchange2;

wire [`DATA_WIDTH] ROB_s_value_b2_;
wire ROB_s_ready_b2_;
wire [`DATA_WIDTH] ROB_s_jumppc_b2_;

//SLB
wire RS_to_SLB_needchange;

wire [`DATA_WIDTH] RS_to_SLB_value;


/* do_SLB() */
//RS and ROB
wire [`ROB_LR_WIDTH] b4;

//memctrl
wire memctrl_data_ok;
wire [`DATA_WIDTH] memctrl_data_ans;

wire SLB_to_memctrl_needchange;//load
wire SLB_to_memctrl_needchange2;//store

wire [`INST_TYPE_WIDTH] SLB_to_memctrl_ordertype;
wire [`DATA_WIDTH] SLB_to_memctrl_vj;
wire [`DATA_WIDTH] SLB_to_memctrl_vk;
wire [`DATA_WIDTH] SLB_to_memctrl_A;

//ROB
wire SLB_to_ROB_needchange;
wire [`DATA_WIDTH] ROB_s_value_b4_;
wire ROB_s_ready_b4_;

//RS
wire SLB_to_RS_needchange;
wire [`DATA_WIDTH] SLB_to_RS_loadvalue;



InstQueue u_InstQueue(
    .clk                            ( clk_in                            ),
    .rst                            ( rst_in                            ),
    .rdy                            ( rdy_in                            ),
    .Clear_flag                     ( Clear_flag                     ),
    .memctrl_ins_ok                 ( memctrl_ins_ok                 ),
    .memctrl_ins_ans                ( memctrl_ins_ans                ),
    .insqueue_to_memctrl_needchange ( insqueue_to_memctrl_needchange ),
    .memctrl_ins_addr_              ( memctrl_ins_addr_              ),
    .memctrl_ins_remain_cycle_      ( memctrl_ins_remain_cycle_      ),
    .addr1                          ( addr1                          ),
    .hit_in                         ( hit                         ),
    .returnInst                     ( returnInst                     ),
    .insqueue_to_ICache_needchange  ( insqueue_to_ICache_needchange  ),
    .addr2                          ( addr2                          ),
    .storeInst                      ( storeInst                      ),
    .bht_id1                        ( bht_id1                        ),
    .bht_get                        ( bht_get                        ),
    .h1                             ( h1                             ),
    .h2                             ( h2                             ),
    .ROB_size                       ( ROB_size                       ),
    .ROB_R                          ( ROB_R                          ),
    .ROB_s_ready_h1                 ( ROB_s_ready_h1                 ),
    .ROB_s_value_h1                 ( ROB_s_value_h1                 ),
    .ROB_s_ready_h2                 ( ROB_s_ready_h2                 ),
    .ROB_s_value_h2                 ( ROB_s_value_h2                 ),
    .insqueue_to_ROB_needchange     ( insqueue_to_ROB_needchange     ),
    .insqueue_to_ROB_size_addflag   ( insqueue_to_ROB_size_addflag   ),
    .b1                             ( b1                             ),
    .ROB_R_                         ( ROB_R_                         ),
    .ROB_s_pc_b1_                   ( ROB_s_pc_b1_                   ),
    .ROB_s_inst_b1_                 ( ROB_s_inst_b1_                 ),
    .ROB_s_ordertype_b1_            ( ROB_s_ordertype_b1_            ),
    .ROB_s_dest_b1_                 ( ROB_s_dest_b1_                 ),
    .ROB_s_jumppc_b1_               ( ROB_s_jumppc_b1_               ),
    .ROB_s_isjump_b1_               ( ROB_s_isjump_b1_               ),
    .ROB_s_ready_b1_                ( ROB_s_ready_b1_                ),
    .RS_unbusy_pos                  ( RS_unbusy_pos                  ),
    .insqueue_to_RS_needchange      ( insqueue_to_RS_needchange      ),
    .r2                             ( r2                             ),
    .RS_s_vj_r2_                    ( RS_s_vj_r2_                    ),
    .RS_s_vk_r2_                    ( RS_s_vk_r2_                    ),
    .RS_s_qj_r2_                    ( RS_s_qj_r2_                    ),
    .RS_s_qk_r2_                    ( RS_s_qk_r2_                    ),
    .RS_s_inst_r2_                  ( RS_s_inst_r2_                  ),
    .RS_s_ordertype_r2_             ( RS_s_ordertype_r2_             ),
    .RS_s_pc_r2_                    ( RS_s_pc_r2_                    ),
    .RS_s_jumppc_r2_                ( RS_s_jumppc_r2_                ),
    .RS_s_A_r2_                     ( RS_s_A_r2_                     ),
    .RS_s_reorder_r2_               ( RS_s_reorder_r2_               ),
    .RS_s_busy_r2_                  ( RS_s_busy_r2_                  ),
    .SLB_size                       ( SLB_size                       ),
    .SLB_R                          ( SLB_R                          ),
    .insqueue_to_SLB_needchange     ( insqueue_to_SLB_needchange     ),
    .insqueue_to_SLB_size_addflag   ( insqueue_to_SLB_size_addflag   ),
    .r1                             ( r1                             ),
    .SLB_R_                         ( SLB_R_                         ),
    .SLB_s_vj_r1_                   ( SLB_s_vj_r1_                   ),
    .SLB_s_vk_r1_                   ( SLB_s_vk_r1_                   ),
    .SLB_s_qj_r1_                   ( SLB_s_qj_r1_                   ),
    .SLB_s_qk_r1_                   ( SLB_s_qk_r1_                   ),
    .SLB_s_inst_r1_                 ( SLB_s_inst_r1_                 ),
    .SLB_s_ordertype_r1_            ( SLB_s_ordertype_r1_            ),
    .SLB_s_pc_r1_                   ( SLB_s_pc_r1_                   ),
    .SLB_s_A_r1_                    ( SLB_s_A_r1_                    ),
    .SLB_s_reorder_r1_              ( SLB_s_reorder_r1_              ),
    .SLB_s_ready_r1_                ( SLB_s_ready_r1_                ),
    .order_rs1                      ( order_rs1                      ),
    .order_rs2                      ( order_rs2                      ),
    .reg_busy_order_rs1             ( reg_busy_order_rs1             ),
    .reg_busy_order_rs2             ( reg_busy_order_rs2             ),
    .reg_reorder_order_rs1          ( reg_reorder_order_rs1          ),
    .reg_reorder_order_rs2          ( reg_reorder_order_rs2          ),
    .reg_reg_order_rs1              ( reg_reg_order_rs1              ),
    .reg_reg_order_rs2              ( reg_reg_order_rs2              ),
    .insqueue_to_Reg_needchange     ( insqueue_to_Reg_needchange     ),
    .order_rd                       ( order_rd                       ),
    .reg_busy_order_rd_             ( reg_busy_order_rd_             ),
    .reg_reorder_order_rd_          ( reg_reorder_order_rd_          ),
    .pc_                            ( pc_                            )
);

ICache u_ICache(
    .clk                            ( clk_in                                ),
    .rst                            ( rst_in                                ),
    .rdy                            ( rdy_in                                ),
    .addr1                          ( addr1                             ),
    .hit                            ( hit                               ),
    .returnInst                     ( returnInst                        ),
    .insqueue_to_ICache_needchange  ( insqueue_to_ICache_needchange     ),
    .addr2                          ( addr2                             ),
    .storeInst                      ( storeInst                         )
);

MemCtrl u_MemCtrl(
    .clk                            ( clk_in                            ),
    .rst                            ( rst_in                            ),
    .rdy                            ( rdy_in                            ),
    .io_buffer_full                 ( io_buffer_full                    ),
    .r_or_w                         ( mem_wr                        ),
    .a_in                           ( mem_a                           ),
    .d_in                           ( mem_dout                           ),
    .d_out                          ( mem_din                          ),
    .Clear_flag                     ( Clear_flag                     ),
    .memctrl_ins_ok__               ( memctrl_ins_ok               ),
    .memctrl_ins_ans__              ( memctrl_ins_ans              ),
    .insqueue_to_memctrl_needchange ( insqueue_to_memctrl_needchange ),
    .memctrl_ins_addr_              ( memctrl_ins_addr_              ),
    .memctrl_ins_remain_cycle_      ( memctrl_ins_remain_cycle_      ),
    .memctrl_data_ok__              ( memctrl_data_ok              ),
    .memctrl_data_ans__             ( memctrl_data_ans             ),
    .SLB_to_memctrl_needchange      ( SLB_to_memctrl_needchange      ),
    .SLB_to_memctrl_needchange2     ( SLB_to_memctrl_needchange2     ),
    .SLB_to_memctrl_ordertype       ( SLB_to_memctrl_ordertype       ),
    .SLB_to_memctrl_vj              ( SLB_to_memctrl_vj              ),
    .SLB_to_memctrl_vk              ( SLB_to_memctrl_vk              ),
    .SLB_to_memctrl_A               ( SLB_to_memctrl_A               )
);


Reg u_Reg(
    .clk                        ( clk_in                        ),
    .rst                        ( rst_in                        ),
    .rdy                        ( rdy_in                        ),
    .Clear_flag                 ( Clear_flag                 ),
    .order_rs1                  ( order_rs1                  ),
    .order_rs2                  ( order_rs2                  ),
    .reg_busy_order_rs1         ( reg_busy_order_rs1         ),
    .reg_busy_order_rs2         ( reg_busy_order_rs2         ),
    .reg_reorder_order_rs1      ( reg_reorder_order_rs1      ),
    .reg_reorder_order_rs2      ( reg_reorder_order_rs2      ),
    .reg_reg_order_rs1          ( reg_reg_order_rs1          ),
    .reg_reg_order_rs2          ( reg_reg_order_rs2          ),
    .insqueue_to_Reg_needchange ( insqueue_to_Reg_needchange ),
    .order_rd                   ( order_rd                   ),
    .reg_busy_order_rd_         ( reg_busy_order_rd_         ),
    .reg_reorder_order_rd_      ( reg_reorder_order_rd_      ),
    .commit_rd                  ( commit_rd                  ),
    .reg_busy_commit_rd         ( reg_busy_commit_rd         ),
    .reg_reorder_commit_rd      ( reg_reorder_commit_rd      ),
    .ROB_to_Reg_needchange      ( ROB_to_Reg_needchange      ),
    .ROB_to_Reg_needchange2     ( ROB_to_Reg_needchange2     ),
    .reg_reg_commit_rd_         ( reg_reg_commit_rd_         ),
    .reg_busy_commit_rd_        ( reg_busy_commit_rd_        )
);

ROB u_ROB(
    .clk                          ( clk_in                          ),
    .rst                          ( rst_in                          ),
    .rdy                          ( rdy_in                          ),
    .Clear_flag                   ( Clear_flag                   ),
    .b3                           ( b3                           ),
    .ROB_to_BHT_needchange        ( ROB_to_BHT_needchange        ),
    .ROB_to_BHT_needchange2       ( ROB_to_BHT_needchange2       ),
    .bht_id2                      ( bht_id2                      ),
    .ROB_to_RS_needchange         ( ROB_to_RS_needchange         ),
    .ROB_to_RS_value_b3           ( ROB_to_RS_value_b3           ),
    .ROB_to_SLB_needchange        ( ROB_to_SLB_needchange        ),
    .ROB_to_SLB_needchange2       ( ROB_to_SLB_needchange2       ),
    .ROB_to_SLB_value_b3          ( ROB_to_SLB_value_b3          ),
    .commit_rd                    ( commit_rd                    ),
    .reg_busy_commit_rd           ( reg_busy_commit_rd           ),
    .reg_reorder_commit_rd        ( reg_reorder_commit_rd        ),
    .ROB_to_Reg_needchange        ( ROB_to_Reg_needchange        ),
    .ROB_to_Reg_needchange2       ( ROB_to_Reg_needchange2       ),
    .reg_reg_commit_rd_           ( reg_reg_commit_rd_           ),
    .reg_busy_commit_rd_          ( reg_busy_commit_rd_          ),
    .pc_                          ( pc_                          ),
    .Clear_flag_                  ( Clear_flag                  ),
    .h1                           ( h1                           ),
    .h2                           ( h2                           ),
    .ROB_size__                   ( ROB_size                   ),
    .ROB_R__                      ( ROB_R                      ),
    .ROB_s_ready_h1               ( ROB_s_ready_h1               ),
    .ROB_s_value_h1               ( ROB_s_value_h1               ),
    .ROB_s_ready_h2               ( ROB_s_ready_h2               ),
    .ROB_s_value_h2               ( ROB_s_value_h2               ),
    .insqueue_to_ROB_needchange   ( insqueue_to_ROB_needchange   ),
    .insqueue_to_ROB_size_addflag ( insqueue_to_ROB_size_addflag ),
    .b1                           ( b1                           ),
    .ROB_R_                       ( ROB_R_                       ),
    .ROB_s_pc_b1_                 ( ROB_s_pc_b1_                 ),
    .ROB_s_inst_b1_               ( ROB_s_inst_b1_               ),
    .ROB_s_ordertype_b1_          ( ROB_s_ordertype_b1_          ),
    .ROB_s_dest_b1_               ( ROB_s_dest_b1_               ),
    .ROB_s_jumppc_b1_             ( ROB_s_jumppc_b1_             ),
    .ROB_s_isjump_b1_             ( ROB_s_isjump_b1_             ),
    .ROB_s_ready_b1_              ( ROB_s_ready_b1_              ),
    .RS_to_ROB_needchange         ( RS_to_ROB_needchange         ),
    .RS_to_ROB_needchange2        ( RS_to_ROB_needchange2        ),
    .b2                           ( b2                           ),
    .ROB_s_value_b2_              ( ROB_s_value_b2_              ),
    .ROB_s_ready_b2_              ( ROB_s_ready_b2_              ),
    .ROB_s_jumppc_b2_             ( ROB_s_jumppc_b2_             ),
    .SLB_to_ROB_needchange        ( SLB_to_ROB_needchange        ),
    .b4                           ( b4                           ),
    .ROB_s_value_b4_              ( ROB_s_value_b4_              ),
    .ROB_s_ready_b4_              ( ROB_s_ready_b4_              )
);

RS u_RS(
    .clk                       ( clk_in                       ),
    .rst                       ( rst_in                       ),
    .rdy                       ( rdy_in                       ),
    .Clear_flag                ( Clear_flag                ),
    .b2                        ( b2                        ),
    .RS_to_ROB_needchange      ( RS_to_ROB_needchange      ),
    .RS_to_ROB_needchange2     ( RS_to_ROB_needchange2     ),
    .ROB_s_value_b2_           ( ROB_s_value_b2_           ),
    .ROB_s_ready_b2_           ( ROB_s_ready_b2_           ),
    .ROB_s_jumppc_b2_          ( ROB_s_jumppc_b2_          ),
    .RS_to_SLB_needchange      ( RS_to_SLB_needchange      ),
    .RS_to_SLB_value           ( RS_to_SLB_value           ),
    .RS_unbusy_pos             ( RS_unbusy_pos             ),
    .insqueue_to_RS_needchange ( insqueue_to_RS_needchange ),
    .r2                        ( r2                        ),
    .RS_s_vj_r2_               ( RS_s_vj_r2_               ),
    .RS_s_vk_r2_               ( RS_s_vk_r2_               ),
    .RS_s_qj_r2_               ( RS_s_qj_r2_               ),
    .RS_s_qk_r2_               ( RS_s_qk_r2_               ),
    .RS_s_inst_r2_             ( RS_s_inst_r2_             ),
    .RS_s_ordertype_r2_        ( RS_s_ordertype_r2_        ),
    .RS_s_pc_r2_               ( RS_s_pc_r2_               ),
    .RS_s_jumppc_r2_           ( RS_s_jumppc_r2_           ),
    .RS_s_A_r2_                ( RS_s_A_r2_                ),
    .RS_s_reorder_r2_          ( RS_s_reorder_r2_          ),
    .RS_s_busy_r2_             ( RS_s_busy_r2_             ),
    .b3                        ( b3                        ),
    .ROB_to_RS_needchange      ( ROB_to_RS_needchange      ),
    .ROB_to_RS_value_b3        ( ROB_to_RS_value_b3        ),
    .SLB_to_RS_needchange      ( SLB_to_RS_needchange      ),
    .SLB_to_RS_loadvalue       ( SLB_to_RS_loadvalue       ),
    .b4                        ( b4                        )
);

SLB u_SLB(
    .clk                          ( clk_in                          ),
    .rst                          ( rst_in                          ),
    .rdy                          ( rdy_in                          ),
    .Clear_flag                   ( Clear_flag                   ),
    .SLB_size__                   ( SLB_size                   ),
    .SLB_R__                      ( SLB_R                      ),
    .insqueue_to_SLB_needchange   ( insqueue_to_SLB_needchange   ),
    .insqueue_to_SLB_size_addflag ( insqueue_to_SLB_size_addflag ),
    .r1                           ( r1                           ),
    .SLB_R_                       ( SLB_R_                       ),
    .SLB_s_vj_r1_                 ( SLB_s_vj_r1_                 ),
    .SLB_s_vk_r1_                 ( SLB_s_vk_r1_                 ),
    .SLB_s_qj_r1_                 ( SLB_s_qj_r1_                 ),
    .SLB_s_qk_r1_                 ( SLB_s_qk_r1_                 ),
    .SLB_s_inst_r1_               ( SLB_s_inst_r1_               ),
    .SLB_s_ordertype_r1_          ( SLB_s_ordertype_r1_          ),
    .SLB_s_pc_r1_                 ( SLB_s_pc_r1_                 ),
    .SLB_s_A_r1_                  ( SLB_s_A_r1_                  ),
    .SLB_s_reorder_r1_            ( SLB_s_reorder_r1_            ),
    .SLB_s_ready_r1_              ( SLB_s_ready_r1_              ),
    .b4                           ( b4                           ),
    .memctrl_data_ok              ( memctrl_data_ok              ),
    .memctrl_data_ans             ( memctrl_data_ans             ),
    .SLB_to_memctrl_needchange    ( SLB_to_memctrl_needchange    ),
    .SLB_to_memctrl_needchange2   ( SLB_to_memctrl_needchange2   ),
    .SLB_to_memctrl_ordertype     ( SLB_to_memctrl_ordertype     ),
    .SLB_to_memctrl_vj            ( SLB_to_memctrl_vj            ),
    .SLB_to_memctrl_vk            ( SLB_to_memctrl_vk            ),
    .SLB_to_memctrl_A             ( SLB_to_memctrl_A             ),
    .SLB_to_ROB_needchange        ( SLB_to_ROB_needchange        ),
    .ROB_s_value_b4_              ( ROB_s_value_b4_              ),
    .ROB_s_ready_b4_              ( ROB_s_ready_b4_              ),
    .SLB_to_RS_needchange         ( SLB_to_RS_needchange         ),
    .SLB_to_RS_loadvalue          ( SLB_to_RS_loadvalue          ),
    .RS_to_SLB_needchange         ( RS_to_SLB_needchange         ),
    .b2                           ( b2                           ),
    .RS_to_SLB_value              ( RS_to_SLB_value              ),
    .b3                           ( b3                           ),
    .ROB_to_SLB_needchange        ( ROB_to_SLB_needchange        ),
    .ROB_to_SLB_needchange2       ( ROB_to_SLB_needchange2       ),
    .ROB_to_SLB_value_b3          ( ROB_to_SLB_value_b3          )
);


BHT u_BHT(
    .clk                    ( clk_in                    ),
    .rst                    ( rst_in                    ),
    .rdy                    ( rdy_in                    ),
    .bht_id1                ( bht_id1                ),
    .bht_get                ( bht_get                ),
    .ROB_to_BHT_needchange  ( ROB_to_BHT_needchange  ),
    .ROB_to_BHT_needchange2 ( ROB_to_BHT_needchange2 ),
    .bht_id2                ( bht_id2                )
);




endmodule