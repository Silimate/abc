// Source of sprove_const_po.aig, a non-equivalent sequential miter: register A stays 0 and
// register B loads input X, so P = A ^ B is 1 from frame 1 (bmc3 asserts it there). &scorr
// proves A constant 0, which leaves P driven by B alone: no AND nodes, but not constant 0.
// Generated with yosys:
//   read_verilog sprove_const_po.v; hierarchy -top top
//   proc; dffunmap; techmap; aigmap; opt_clean
//   write_aiger -zinit sprove_const_po.aig
module top(input CLK, input X, output P);
  reg A = 0, B = 0;
  always @(posedge CLK) begin
    A <= 1'b0;
    B <= X;
  end
  assign P = A ^ B;
endmodule
