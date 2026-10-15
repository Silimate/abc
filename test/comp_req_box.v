// Source of comp_req_box.xaig, the network Yosys's abc9 hands ABC (input.xaig):
//   read_verilog -specify comp_req_box.v; hierarchy -top t; flatten; proc; aigmap
//   abc9 -lut 6 -nocleanup -showtmp
(* abc9_box, whitebox *)
module bx(input a, b, output y);
  assign y = a ^ b;
  specify
    (a => y) = 1;
    (b => y) = 1;
  endspecify
endmodule
module arb(input [15:0] r, b, output [15:0] g, output any);
  wire [15:0] e = r & ~b, s;
  assign g[0] = e[0], s[0] = e[0];
  genvar i;
  for (i = 1; i < 16; i = i + 1) begin : p
    assign g[i] = e[i] & ~s[i-1], s[i] = e[i] | s[i-1];
  end
  assign any = s[15];
endmodule
module t(input [15:0] r, b, r2, b2, input [64:1] a, c, input z0, output [15:0] g, g2, output z);
  wire [64:0] q;
  wire any, any2, u;
  // arbiter g shares no logic with the chain; arbiter g2 starts it, through a box
  arb x(.r(r), .b(b), .g(g), .any(any));
  arb x2(.r(r2), .b(b2), .g(g2), .any(any2));
  bx k(.a(any2), .b(z0), .y(u));
  assign q[0] = u;
  genvar i;
  for (i = 1; i <= 64; i = i + 1) begin : ch
    assign q[i] = (q[i-1] & a[i]) | c[i];
  end
  bx m(.a(q[64]), .b(z0), .y(z));
endmodule
