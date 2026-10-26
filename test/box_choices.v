// Source of box_choices.xaig, the network Yosys's abc9 hands ABC (input.xaig):
//   read_verilog -specify box_choices.v; hierarchy -top t; proc; aigmap
//   abc9 -lut 4 -nocleanup -showtmp
(* abc9_box, whitebox *)
module bx(input a, output y);
  assign y = ~a;
  specify
    (a => y) = 1;
  endspecify
endmodule
module t(input c, d, output y, z);
  // z equals the box input c & d, but is built from the box output y
  bx k(.a(c & d), .y(y));
  assign z = (c & (d & y)) | (d & (c & ~y));
endmodule
