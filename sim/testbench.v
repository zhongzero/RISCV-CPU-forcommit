// testbench top module file
// for simulation only

//`include "/mnt/e/RISCV-CPU/CPU/src/riscv_top.v"
// `include "/RISCV-CPU/CPU/src/riscv_top.v"
// `include "E://RISCV-CPU/CPU/src/riscv_top.v"

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);
integer count=0;

integer cnt=0;
initial begin
  clk=0;
  rst=1;
  repeat(50) begin
    count=count+1;
    // $display("!!!!!!!!!!",count);
    #1 clk=!clk;
    // if(count==10)$finish;
  end
  rst=0; 
  forever begin
    #1 clk=!clk;
    cnt=cnt+1;
    // if (cnt%10==0) $display("cnt",cnt);
  end

  $finish;
end

initial begin
    // $dumpfile("test7.vcd");
    // $dumpvars(0, testbench); // 打开wave记录

    // #5000000 $finish;
end

endmodule
