// Reproducer for a soundness bug in "&sprove": an interrupted signal-correspondence
// reduction is trusted as a proof.
//
// "&sprove" runs "&scorr" (scnew) concurrently with its solver engines, under a stop
// callback (first-stage timeout -T, or "another engine finished"). When the callback
// interrupts the reduction before it converges, the candidate equivalences it has
// collected are NOT yet proven inductive. &sprove nonetheless uses the reduced AIG: if
// it has 0 ANDs it declares UNSATISFIABLE, and later stages solve on it.
//
// This miter has a single property output P that is 0 for the first 120 cycles and
// becomes 1 at cycle 120 (bmc3 finds the assertion in frame 120, so the miter is NOT
// equivalent / P is SATISFIABLE). It is 80 parallel shift chains of length 120, each
// triggered at a distinct, deep counter value that shallow random simulation never
// reaches; P is the OR of all chain ends. Every chain flop therefore looks like a
// constant-0 candidate, and the reduction needs ~120 refinement iterations over ~9600
// flops to peel them apart -- long enough that "&sprove -T 1" interrupts it with the
// chains still merged. The interrupted sweep collapses the whole miter to a constant 0
// and &sprove reports:
//
//     &read sprove_scorr_stop.aig; &sprove -T 1
//     => "... is UNSATISFIABLE (solved by scnew)."     (WRONG; the miter is SAT)
//
// while bmc3 proves it SATISFIABLE:
//
//     read_aiger sprove_scorr_stop.aig; bmc3 -F 160
//     => "Output 0 ... was asserted in frame 120."
//
// Generated from this file with yosys:
//     read_verilog -sv sprove_scorr_stop.v; hierarchy -top top
//     proc; flatten; opt; memory; opt; techmap; opt; dffunmap; aigmap; opt_clean
//     write_aiger -zinit sprove_scorr_stop.aig
module top(input CLK, output P);
  reg [7:0] cnt = 0;
  always @(posedge CLK) cnt <= cnt + 1;
  reg [119:0] ch0 = 0;  wire t0 = (cnt == 0);
  always @(posedge CLK) ch0 <= {ch0[118:0], t0};
  reg [119:0] ch1 = 0;  wire t1 = (cnt == 1);
  always @(posedge CLK) ch1 <= {ch1[118:0], t1};
  reg [119:0] ch2 = 0;  wire t2 = (cnt == 2);
  always @(posedge CLK) ch2 <= {ch2[118:0], t2};
  reg [119:0] ch3 = 0;  wire t3 = (cnt == 3);
  always @(posedge CLK) ch3 <= {ch3[118:0], t3};
  reg [119:0] ch4 = 0;  wire t4 = (cnt == 4);
  always @(posedge CLK) ch4 <= {ch4[118:0], t4};
  reg [119:0] ch5 = 0;  wire t5 = (cnt == 5);
  always @(posedge CLK) ch5 <= {ch5[118:0], t5};
  reg [119:0] ch6 = 0;  wire t6 = (cnt == 6);
  always @(posedge CLK) ch6 <= {ch6[118:0], t6};
  reg [119:0] ch7 = 0;  wire t7 = (cnt == 7);
  always @(posedge CLK) ch7 <= {ch7[118:0], t7};
  reg [119:0] ch8 = 0;  wire t8 = (cnt == 8);
  always @(posedge CLK) ch8 <= {ch8[118:0], t8};
  reg [119:0] ch9 = 0;  wire t9 = (cnt == 9);
  always @(posedge CLK) ch9 <= {ch9[118:0], t9};
  reg [119:0] ch10 = 0;  wire t10 = (cnt == 10);
  always @(posedge CLK) ch10 <= {ch10[118:0], t10};
  reg [119:0] ch11 = 0;  wire t11 = (cnt == 11);
  always @(posedge CLK) ch11 <= {ch11[118:0], t11};
  reg [119:0] ch12 = 0;  wire t12 = (cnt == 12);
  always @(posedge CLK) ch12 <= {ch12[118:0], t12};
  reg [119:0] ch13 = 0;  wire t13 = (cnt == 13);
  always @(posedge CLK) ch13 <= {ch13[118:0], t13};
  reg [119:0] ch14 = 0;  wire t14 = (cnt == 14);
  always @(posedge CLK) ch14 <= {ch14[118:0], t14};
  reg [119:0] ch15 = 0;  wire t15 = (cnt == 15);
  always @(posedge CLK) ch15 <= {ch15[118:0], t15};
  reg [119:0] ch16 = 0;  wire t16 = (cnt == 16);
  always @(posedge CLK) ch16 <= {ch16[118:0], t16};
  reg [119:0] ch17 = 0;  wire t17 = (cnt == 17);
  always @(posedge CLK) ch17 <= {ch17[118:0], t17};
  reg [119:0] ch18 = 0;  wire t18 = (cnt == 18);
  always @(posedge CLK) ch18 <= {ch18[118:0], t18};
  reg [119:0] ch19 = 0;  wire t19 = (cnt == 19);
  always @(posedge CLK) ch19 <= {ch19[118:0], t19};
  reg [119:0] ch20 = 0;  wire t20 = (cnt == 20);
  always @(posedge CLK) ch20 <= {ch20[118:0], t20};
  reg [119:0] ch21 = 0;  wire t21 = (cnt == 21);
  always @(posedge CLK) ch21 <= {ch21[118:0], t21};
  reg [119:0] ch22 = 0;  wire t22 = (cnt == 22);
  always @(posedge CLK) ch22 <= {ch22[118:0], t22};
  reg [119:0] ch23 = 0;  wire t23 = (cnt == 23);
  always @(posedge CLK) ch23 <= {ch23[118:0], t23};
  reg [119:0] ch24 = 0;  wire t24 = (cnt == 24);
  always @(posedge CLK) ch24 <= {ch24[118:0], t24};
  reg [119:0] ch25 = 0;  wire t25 = (cnt == 25);
  always @(posedge CLK) ch25 <= {ch25[118:0], t25};
  reg [119:0] ch26 = 0;  wire t26 = (cnt == 26);
  always @(posedge CLK) ch26 <= {ch26[118:0], t26};
  reg [119:0] ch27 = 0;  wire t27 = (cnt == 27);
  always @(posedge CLK) ch27 <= {ch27[118:0], t27};
  reg [119:0] ch28 = 0;  wire t28 = (cnt == 28);
  always @(posedge CLK) ch28 <= {ch28[118:0], t28};
  reg [119:0] ch29 = 0;  wire t29 = (cnt == 29);
  always @(posedge CLK) ch29 <= {ch29[118:0], t29};
  reg [119:0] ch30 = 0;  wire t30 = (cnt == 30);
  always @(posedge CLK) ch30 <= {ch30[118:0], t30};
  reg [119:0] ch31 = 0;  wire t31 = (cnt == 31);
  always @(posedge CLK) ch31 <= {ch31[118:0], t31};
  reg [119:0] ch32 = 0;  wire t32 = (cnt == 32);
  always @(posedge CLK) ch32 <= {ch32[118:0], t32};
  reg [119:0] ch33 = 0;  wire t33 = (cnt == 33);
  always @(posedge CLK) ch33 <= {ch33[118:0], t33};
  reg [119:0] ch34 = 0;  wire t34 = (cnt == 34);
  always @(posedge CLK) ch34 <= {ch34[118:0], t34};
  reg [119:0] ch35 = 0;  wire t35 = (cnt == 35);
  always @(posedge CLK) ch35 <= {ch35[118:0], t35};
  reg [119:0] ch36 = 0;  wire t36 = (cnt == 36);
  always @(posedge CLK) ch36 <= {ch36[118:0], t36};
  reg [119:0] ch37 = 0;  wire t37 = (cnt == 37);
  always @(posedge CLK) ch37 <= {ch37[118:0], t37};
  reg [119:0] ch38 = 0;  wire t38 = (cnt == 38);
  always @(posedge CLK) ch38 <= {ch38[118:0], t38};
  reg [119:0] ch39 = 0;  wire t39 = (cnt == 39);
  always @(posedge CLK) ch39 <= {ch39[118:0], t39};
  reg [119:0] ch40 = 0;  wire t40 = (cnt == 40);
  always @(posedge CLK) ch40 <= {ch40[118:0], t40};
  reg [119:0] ch41 = 0;  wire t41 = (cnt == 41);
  always @(posedge CLK) ch41 <= {ch41[118:0], t41};
  reg [119:0] ch42 = 0;  wire t42 = (cnt == 42);
  always @(posedge CLK) ch42 <= {ch42[118:0], t42};
  reg [119:0] ch43 = 0;  wire t43 = (cnt == 43);
  always @(posedge CLK) ch43 <= {ch43[118:0], t43};
  reg [119:0] ch44 = 0;  wire t44 = (cnt == 44);
  always @(posedge CLK) ch44 <= {ch44[118:0], t44};
  reg [119:0] ch45 = 0;  wire t45 = (cnt == 45);
  always @(posedge CLK) ch45 <= {ch45[118:0], t45};
  reg [119:0] ch46 = 0;  wire t46 = (cnt == 46);
  always @(posedge CLK) ch46 <= {ch46[118:0], t46};
  reg [119:0] ch47 = 0;  wire t47 = (cnt == 47);
  always @(posedge CLK) ch47 <= {ch47[118:0], t47};
  reg [119:0] ch48 = 0;  wire t48 = (cnt == 48);
  always @(posedge CLK) ch48 <= {ch48[118:0], t48};
  reg [119:0] ch49 = 0;  wire t49 = (cnt == 49);
  always @(posedge CLK) ch49 <= {ch49[118:0], t49};
  reg [119:0] ch50 = 0;  wire t50 = (cnt == 50);
  always @(posedge CLK) ch50 <= {ch50[118:0], t50};
  reg [119:0] ch51 = 0;  wire t51 = (cnt == 51);
  always @(posedge CLK) ch51 <= {ch51[118:0], t51};
  reg [119:0] ch52 = 0;  wire t52 = (cnt == 52);
  always @(posedge CLK) ch52 <= {ch52[118:0], t52};
  reg [119:0] ch53 = 0;  wire t53 = (cnt == 53);
  always @(posedge CLK) ch53 <= {ch53[118:0], t53};
  reg [119:0] ch54 = 0;  wire t54 = (cnt == 54);
  always @(posedge CLK) ch54 <= {ch54[118:0], t54};
  reg [119:0] ch55 = 0;  wire t55 = (cnt == 55);
  always @(posedge CLK) ch55 <= {ch55[118:0], t55};
  reg [119:0] ch56 = 0;  wire t56 = (cnt == 56);
  always @(posedge CLK) ch56 <= {ch56[118:0], t56};
  reg [119:0] ch57 = 0;  wire t57 = (cnt == 57);
  always @(posedge CLK) ch57 <= {ch57[118:0], t57};
  reg [119:0] ch58 = 0;  wire t58 = (cnt == 58);
  always @(posedge CLK) ch58 <= {ch58[118:0], t58};
  reg [119:0] ch59 = 0;  wire t59 = (cnt == 59);
  always @(posedge CLK) ch59 <= {ch59[118:0], t59};
  reg [119:0] ch60 = 0;  wire t60 = (cnt == 60);
  always @(posedge CLK) ch60 <= {ch60[118:0], t60};
  reg [119:0] ch61 = 0;  wire t61 = (cnt == 61);
  always @(posedge CLK) ch61 <= {ch61[118:0], t61};
  reg [119:0] ch62 = 0;  wire t62 = (cnt == 62);
  always @(posedge CLK) ch62 <= {ch62[118:0], t62};
  reg [119:0] ch63 = 0;  wire t63 = (cnt == 63);
  always @(posedge CLK) ch63 <= {ch63[118:0], t63};
  reg [119:0] ch64 = 0;  wire t64 = (cnt == 64);
  always @(posedge CLK) ch64 <= {ch64[118:0], t64};
  reg [119:0] ch65 = 0;  wire t65 = (cnt == 65);
  always @(posedge CLK) ch65 <= {ch65[118:0], t65};
  reg [119:0] ch66 = 0;  wire t66 = (cnt == 66);
  always @(posedge CLK) ch66 <= {ch66[118:0], t66};
  reg [119:0] ch67 = 0;  wire t67 = (cnt == 67);
  always @(posedge CLK) ch67 <= {ch67[118:0], t67};
  reg [119:0] ch68 = 0;  wire t68 = (cnt == 68);
  always @(posedge CLK) ch68 <= {ch68[118:0], t68};
  reg [119:0] ch69 = 0;  wire t69 = (cnt == 69);
  always @(posedge CLK) ch69 <= {ch69[118:0], t69};
  reg [119:0] ch70 = 0;  wire t70 = (cnt == 70);
  always @(posedge CLK) ch70 <= {ch70[118:0], t70};
  reg [119:0] ch71 = 0;  wire t71 = (cnt == 71);
  always @(posedge CLK) ch71 <= {ch71[118:0], t71};
  reg [119:0] ch72 = 0;  wire t72 = (cnt == 72);
  always @(posedge CLK) ch72 <= {ch72[118:0], t72};
  reg [119:0] ch73 = 0;  wire t73 = (cnt == 73);
  always @(posedge CLK) ch73 <= {ch73[118:0], t73};
  reg [119:0] ch74 = 0;  wire t74 = (cnt == 74);
  always @(posedge CLK) ch74 <= {ch74[118:0], t74};
  reg [119:0] ch75 = 0;  wire t75 = (cnt == 75);
  always @(posedge CLK) ch75 <= {ch75[118:0], t75};
  reg [119:0] ch76 = 0;  wire t76 = (cnt == 76);
  always @(posedge CLK) ch76 <= {ch76[118:0], t76};
  reg [119:0] ch77 = 0;  wire t77 = (cnt == 77);
  always @(posedge CLK) ch77 <= {ch77[118:0], t77};
  reg [119:0] ch78 = 0;  wire t78 = (cnt == 78);
  always @(posedge CLK) ch78 <= {ch78[118:0], t78};
  reg [119:0] ch79 = 0;  wire t79 = (cnt == 79);
  always @(posedge CLK) ch79 <= {ch79[118:0], t79};
  assign P = ch0[119] | ch1[119] | ch2[119] | ch3[119] | ch4[119] | ch5[119] | ch6[119] | ch7[119] | ch8[119] | ch9[119] | ch10[119] | ch11[119] | ch12[119] | ch13[119] | ch14[119] | ch15[119] | ch16[119] | ch17[119] | ch18[119] | ch19[119] | ch20[119] | ch21[119] | ch22[119] | ch23[119] | ch24[119] | ch25[119] | ch26[119] | ch27[119] | ch28[119] | ch29[119] | ch30[119] | ch31[119] | ch32[119] | ch33[119] | ch34[119] | ch35[119] | ch36[119] | ch37[119] | ch38[119] | ch39[119] | ch40[119] | ch41[119] | ch42[119] | ch43[119] | ch44[119] | ch45[119] | ch46[119] | ch47[119] | ch48[119] | ch49[119] | ch50[119] | ch51[119] | ch52[119] | ch53[119] | ch54[119] | ch55[119] | ch56[119] | ch57[119] | ch58[119] | ch59[119] | ch60[119] | ch61[119] | ch62[119] | ch63[119] | ch64[119] | ch65[119] | ch66[119] | ch67[119] | ch68[119] | ch69[119] | ch70[119] | ch71[119] | ch72[119] | ch73[119] | ch74[119] | ch75[119] | ch76[119] | ch77[119] | ch78[119] | ch79[119];
endmodule
