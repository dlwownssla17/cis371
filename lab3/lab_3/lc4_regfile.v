/* Contributors: Jae Joon Lee (jjlee), Hannes Leipold (leipoldh), Becky Baumher (rbaumher)
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 * Contributions: This file has been implemented by Jae Joon Lee.
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

   wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;
   
   Nbit_reg #(n) r0 (i_wdata, r0v, clk, (i_rd == 3'd0) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r1 (i_wdata, r1v, clk, (i_rd == 3'd1) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r2 (i_wdata, r2v, clk, (i_rd == 3'd2) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r3 (i_wdata, r3v, clk, (i_rd == 3'd3) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r4 (i_wdata, r4v, clk, (i_rd == 3'd4) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r5 (i_wdata, r5v, clk, (i_rd == 3'd5) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r6 (i_wdata, r6v, clk, (i_rd == 3'd6) & i_rd_we, gwe, rst);
   Nbit_reg #(n) r7 (i_wdata, r7v, clk, (i_rd == 3'd7) & i_rd_we, gwe, rst);
   Nbit_mux8to1 #(n) mux1 (i_rs, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rs_data);
   Nbit_mux8to1 #(n) mux2 (i_rt, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rt_data);

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
