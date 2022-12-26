//width
`define DATA_WIDTH 31:0
`define INST_TYPE_WIDTH 5:0
`define INSQUEUE_LR_WIDTH 31:0 //temporary
`define SLB_LR_WIDTH 31:0 //temporary
`define ROB_LR_WIDTH 31:0 //temporary
`define RS_LR_WIDTH 31:0 //temporary
`define BHT_LR_WIDTH 7:0 //temporary
`define ICache_TAG_WIDTH 26:0 //temporary
`define RAM_DATA_WIDTH 7:0


//size
`define MaxIns 32
`define MaxRS 16
`define MaxROB 16
`define MaxSLB 16
`define MaxReg 32
`define ICacheIndexSize 7
`define MaxICache 128
`define MaxBHT (1<<8)



//inst_type

//U类型 用于操作长立即数的指�? 0~1
`define LUI 6'd0
`define AUIPC 6'd1

//R类型 寄存器间操作指令 2~11
`define ADD 6'd2
`define SUB 6'd3
`define SLL 6'd4
`define SLT 6'd5
`define SLTU 6'd6
`define XOR 6'd7
`define SRL 6'd8
`define SRA 6'd9
`define OR 6'd10
`define AND 6'd11

//I类型 短立即数和访存Load操作指令 12~26
`define JALR 6'd12
`define LB 6'd13
`define LH 6'd14
`define LW 6'd15
`define LBU 6'd16
`define LHU 6'd17
`define ADDI 6'd18
`define SLTI 6'd19
`define SLTIU 6'd20
`define XORI 6'd21
`define ORI 6'd22
`define ANDI 6'd23
`define SLLI 6'd24
`define SRLI 6'd25
`define SRAI 6'd26

//S类型 访存Store操作指令 27~29
`define SB 6'd27
`define SH 6'd28
`define SW 6'd29

//J类型 用于无条件跳转的指令 30
`define JAL 6'd30

//B类型 用于有条件跳转的指令 31~36
`define BEQ 6'd31
`define BNE 6'd32
`define BLT 6'd33
`define BGE 6'd34
`define BLTU 6'd35
`define BGEU 6'd36
