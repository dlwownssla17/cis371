`timescale 1ns / 1ps

/* Prevent implicit wire declaration
 *
 * This directive will cause Vivado to give an error if you
 * haven't declared a wire (including if you have a typo.
 * 
 * The price you pay for this is that you have to write
 * "input wire" and "output wire" for all your ports
 * instead of just "input" and "output".
 * 
 * All the provided infrastructure code has been updated.
 */
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** Your Code Here ***/
   wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;
   wire [n-1:0] r0d, r1d, r2d, r3d, r4d, r5d, r6d, r7d;
   wire r0weA, r1weA, r2weA, r3weA, r4weA, r5weA, r6weA, r7weA;
   wire r0weB, r1weB, r2weB, r3weB, r4weB, r5weB, r6weB, r7weB;

   
   assign r0weA = (i_rd_A == 3'd0) & i_rd_we_A;
   assign r0weB = (i_rd_B == 3'd0) & i_rd_we_B;
   assign r1weA = (i_rd_A == 3'd1) & i_rd_we_A;
   assign r1weB = (i_rd_B == 3'd1) & i_rd_we_B;
   assign r2weA = (i_rd_A == 3'd2) & i_rd_we_A;
   assign r2weB = (i_rd_B == 3'd2) & i_rd_we_B;
   assign r3weA = (i_rd_A == 3'd3) & i_rd_we_A;
   assign r3weB = (i_rd_B == 3'd3) & i_rd_we_B;
   assign r4weA = (i_rd_A == 3'd4) & i_rd_we_A;
   assign r4weB = (i_rd_B == 3'd4) & i_rd_we_B;
   assign r5weA = (i_rd_A == 3'd5) & i_rd_we_A;
   assign r5weB = (i_rd_B == 3'd5) & i_rd_we_B;
   assign r6weA = (i_rd_A == 3'd6) & i_rd_we_A;
   assign r6weB = (i_rd_B == 3'd6) & i_rd_we_B;
   assign r7weA = (i_rd_A == 3'd7) & i_rd_we_A;
   assign r7weB = (i_rd_B == 3'd7) & i_rd_we_B;
   
   assign r0d = r0weB ? i_wdata_B : i_wdata_A;
   assign r1d = r1weB ? i_wdata_B : i_wdata_A;
   assign r2d = r2weB ? i_wdata_B : i_wdata_A;
   assign r3d = r3weB ? i_wdata_B : i_wdata_A;
   assign r4d = r4weB ? i_wdata_B : i_wdata_A;
   assign r5d = r5weB ? i_wdata_B : i_wdata_A;
   assign r6d = r6weB ? i_wdata_B : i_wdata_A;
   assign r7d = r7weB ? i_wdata_B : i_wdata_A;
   

   /*** bypass!!! and change i_wdataA/B **/
   Nbit_reg #(n) r0 (r0d, r0v, clk, r0weA || r0weB, gwe, rst);
   Nbit_reg #(n) r1 (r1d, r1v, clk, r1weA || r1weB, gwe, rst);
   Nbit_reg #(n) r2 (r2d, r2v, clk, r2weA || r2weB, gwe, rst);
   Nbit_reg #(n) r3 (r3d, r3v, clk, r3weA || r3weB, gwe, rst);
   Nbit_reg #(n) r4 (r4d, r4v, clk, r4weA || r4weB, gwe, rst);
   Nbit_reg #(n) r5 (r5d, r5v, clk, r5weA || r5weB, gwe, rst);
   Nbit_reg #(n) r6 (r6d, r6v, clk, r6weA || r6weB, gwe, rst);
   Nbit_reg #(n) r7 (r7d, r7v, clk, r7weA || r7weB, gwe, rst);

   
   Nbit_mux8to1 #(n) mux1A (i_rs_A, ((r0weA || r0weB) ? r0d : r0v), ((r1weA || r1weB) ? r1d : r1v), ((r2weA || r2weB) ? r2d : r2v), ((r3weA || r3weB) ? r3d : r3v), ((r4weA || r4weB) ? r4d : r4v), ((r5weA || r5weB) ? r5d : r5v), ((r6weA || r6weB) ? r6d : r6v), ((r7weA || r7weB) ? r7d : r7v), o_rs_data_A);
   Nbit_mux8to1 #(n) mux2A (i_rt_A, ((r0weA || r0weB) ? r0d : r0v), ((r1weA || r1weB) ? r1d : r1v), ((r2weA || r2weB) ? r2d : r2v), ((r3weA || r3weB) ? r3d : r3v), ((r4weA || r4weB) ? r4d : r4v), ((r5weA || r5weB) ? r5d : r5v), ((r6weA || r6weB) ? r6d : r6v), ((r7weA || r7weB) ? r7d : r7v), o_rt_data_A);
   
   Nbit_mux8to1 #(n) mux1B (i_rs_B, ((r0weA || r0weB) ? r0d : r0v), ((r1weA || r1weB) ? r1d : r1v), ((r2weA || r2weB) ? r2d : r2v), ((r3weA || r3weB) ? r3d : r3v), ((r4weA || r4weB) ? r4d : r4v), ((r5weA || r5weB) ? r5d : r5v), ((r6weA || r6weB) ? r6d : r6v), ((r7weA || r7weB) ? r7d : r7v), o_rs_data_B);
   Nbit_mux8to1 #(n) mux2B (i_rt_B, ((r0weA || r0weB) ? r0d : r0v), ((r1weA || r1weB) ? r1d : r1v), ((r2weA || r2weB) ? r2d : r2v), ((r3weA || r3weB) ? r3d : r3v), ((r4weA || r4weB) ? r4d : r4v), ((r5weA || r5weB) ? r5d : r5v), ((r6weA || r6weB) ? r6d : r6v), ((r7weA || r7weB) ? r7d : r7v), o_rt_data_B);

   
   
   

endmodule


module Nbit_mux8to1 #(parameter n = 16)
   (input  wire [  2:0] i_r,
    input  wire [n-1:0] r0v,
    input  wire [n-1:0] r1v,
    input  wire [n-1:0] r2v,
    input  wire [n-1:0] r3v,
    input  wire [n-1:0] r4v,
    input  wire [n-1:0] r5v,
    input  wire [n-1:0] r6v,
    input  wire [n-1:0] r7v,
    output wire [n-1:0] o_r_data
    );

    assign o_r_data = (i_r == 3'd0) ? r0v :
                      (i_r == 3'd1) ? r1v :
                      (i_r == 3'd2) ? r2v :
                      (i_r == 3'd3) ? r3v :
                      (i_r == 3'd4) ? r4v :
                      (i_r == 3'd5) ? r5v :
                      (i_r == 3'd6) ? r6v : r7v;

endmodule

