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
   
   Nbit_reg #(n) r0 (i_wdata, r0v, clk, ((i_rd_A == 3'd0) & i_rd_we_A) || ((i_rd_B == 3'd0) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r1 (i_wdata, r1v, clk, ((i_rd_A == 3'd1) & i_rd_we_A) || ((i_rd_B == 3'd1) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r2 (i_wdata, r2v, clk, ((i_rd_A == 3'd2) & i_rd_we_A) || ((i_rd_B == 3'd2) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r3 (i_wdata, r3v, clk, ((i_rd_A == 3'd3) & i_rd_we_A) || ((i_rd_B == 3'd3) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r4 (i_wdata, r4v, clk, ((i_rd_A == 3'd4) & i_rd_we_A) || ((i_rd_B == 3'd4) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r5 (i_wdata, r5v, clk, ((i_rd_A == 3'd5) & i_rd_we_A) || ((i_rd_B == 3'd5) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r6 (i_wdata, r6v, clk, ((i_rd_A == 3'd6) & i_rd_we_A) || ((i_rd_B == 3'd6) & i_rd_we_B), gwe, rst);
   Nbit_reg #(n) r7 (i_wdata, r7v, clk, ((i_rd_A == 3'd7) & i_rd_we_A) || ((i_rd_B == 3'd7) & i_rd_we_B), gwe, rst);

   
   Nbit_mux8to1 #(n) mux1A (i_rs_A, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rs_data_A);
   Nbit_mux8to1 #(n) mux2A (i_rt_A, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rt_data_A);
   
   Nbit_mux8to1 #(n) mux1B (i_rs_B, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rs_data_B);
   Nbit_mux8to1 #(n) mux2B (i_rt_B, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rt_data_B);

   
   
   
   
   

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

