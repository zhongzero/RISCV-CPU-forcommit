//`include "/mnt/e/RISCV-CPU/CPU/src/info.v"
// `include "/RISCV-CPU/CPU/src/info.v"
`include "info.v"

module BHT (
	input wire clk,
	input wire rst,
	input wire rdy,

	/* Get_ins_to_queue() */
	//   BranchJudge()
	//insqueue
	input wire [`BHT_LR_WIDTH] bht_id1,	
	output reg bht_get,

	/* do_ROB() */
	//ROB
	input wire ROB_to_BHT_needchange, // predict wrong
	input wire ROB_to_BHT_needchange2, // predict correct
	input wire [`BHT_LR_WIDTH] bht_id2
);


// always @(*) begin
// 	$display("BHT        ","clk=",clk,",rst=",rst,", time=%t",$realtime);
// end


reg BHT_s[`MaxBHT-1:0][1:0];// 00 强不跳； 01 弱不跳； 10 弱跳�? 11 弱不�?

//wire BHT_s_0=BHT_s[bht_id2][0];//for_debug
//wire BHT_s_1=BHT_s[bht_id2][1];//for_debug

integer i;

// BranchJudge()

always @(*) begin
	if(BHT_s[bht_id1][0]==0)bht_get=0;
	else bht_get=1;
//	bht_get=0;//让预测始终失�?
end

reg flagok,g1,g2;
always @(*) begin
    g1=0;//for_latch
    g2=0;//for_latch
    
    flagok=0;
    if(ROB_to_BHT_needchange) begin //predict wrong
        flagok=1;
        if(BHT_s[bht_id2][1]==0) begin
            g1=0;g2=1;
        end
        if(BHT_s[bht_id2][1]==1) begin
            g1=1;g2=0;
        end
//        if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
//            g1=0;g2=1;
//        end
//        if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
//            g1=1;g2=0;
//        end
//        if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
//            g1=0;g2=1;
//        end
//        if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
//            g1=1;g2=0;
//        end
    end
    if(ROB_to_BHT_needchange2) begin //predict correct
        flagok=1;
        if(BHT_s[bht_id2][0]==0) begin
            g1=0;g2=0;
        end
        if(BHT_s[bht_id2][0]==1) begin
            g1=1;g2=1;
        end
//        if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
//            g1=0;g2=0;
//        end
//        if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
//            g1=0;g2=0;
//        end
//        if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
//            g1=1;g2=1;
//        end
//        if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
//            g1=1;g2=1;
//        end
    end
end


always @(posedge clk) begin
	if(rst) begin
		// BHT
		for(i=0;i<`MaxBHT;i=i+1) begin
			BHT_s[i][0]<=0;
			BHT_s[i][1]<=0;
		end
	end
	else if(~rdy) begin
	end
	else begin
		// from ROB
	   if(flagok) begin
	       BHT_s[bht_id2][0]<=g1;BHT_s[bht_id2][1]<=g2;
	   end
//       if(ROB_to_BHT_needchange) begin //predict wrong
//            if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
//                BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=1;
//            end
//            if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
//                BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=0;
//            end
//            if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
//                BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=1;
//            end
//            if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
//                BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=0;
//            end
//        end
//        if(ROB_to_BHT_needchange2) begin //predict correct
//            if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==0) begin
//                BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=0;
//            end
//            if(BHT_s[bht_id2][0]==0&&BHT_s[bht_id2][1]==1) begin
//                BHT_s[bht_id2][0]<=0;BHT_s[bht_id2][1]<=0;
//            end
//            if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==0) begin
//                BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=1;
//            end
//            if(BHT_s[bht_id2][0]==1&&BHT_s[bht_id2][1]==1) begin
//                BHT_s[bht_id2][0]<=1;BHT_s[bht_id2][1]<=1;
//            end
//        end
    end
end



endmodule