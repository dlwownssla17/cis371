/* Jae Joon Lee (jjlee) */

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
`default_nettype nones

`define zero 1'd0
`define one 1'd1

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient, 
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);
                            
   wire [15:0] remainder_shift;
   wire [15:0] remainder_intermediate;
   wire [15:0] quotient_shift;
   wire dividend_msb;
   wire remainder_lt_divisor;
   
   assign remainder_shift = {i_remainder[14:0], `zero};
   assign dividend_msb = i_dividend[15];
   assign remainder_intermediate = remainder_shift | dividend_msb;
   assign quotient_shift = {i_quotient[14:0], `zero};
   assign remainder_lt_divisor = remainder_intermediate < i_divisor;
   assign o_quotient = remainder_lt_divisor ? (quotient_shift | `zero) : (quotient_shift | `one);
   assign o_remainder = remainder_lt_divisor ? remainder_intermediate : remainder_intermediate - i_divisor;
   assign o_dividend = {i_dividend[14:0], `zero};
   
endmodule

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);
   
   wire divisor_is_zero;
   wire [15:0] dividend_1, dividend_2, dividend_3, dividend_4, dividend_5, dividend_6, dividend_7, dividend_8,
               dividend_9, dividend_10, dividend_11, dividend_12, dividend_13, dividend_14, dividend_15, dividend_16;
   wire [15:0] remainder_1, remainder_2, remainder_3, remainder_4, remainder_5, remainder_6, remainder_7, remainder_8,
               remainder_9, remainder_10, remainder_11, remainder_12, remainder_13, remainder_14, remainder_15, remainder_16;
   wire [15:0] quotient_1, quotient_2, quotient_3, quotient_4, quotient_5, quotient_6, quotient_7, quotient_8,
               quotient_9, quotient_10, quotient_11, quotient_12, quotient_13, quotient_14, quotient_15, quotient_16;
   
   assign divisor_is_zero = i_divisor == `zero;
   assign o_remainder = divisor_is_zero ? `zero : remainder_16;
   assign o_quotient = divisor_is_zero ? `zero : quotient_16;
   
   lc4_divider_one_iter div1  (i_dividend, i_divisor, `zero, `zero, dividend_1, remainder_1, quotient_1);
   lc4_divider_one_iter div2  (dividend_1, i_divisor, remainder_1, quotient_1, dividend_2, remainder_2, quotient_2);
   lc4_divider_one_iter div3  (dividend_2, i_divisor, remainder_2, quotient_2, dividend_3, remainder_3, quotient_3);
   lc4_divider_one_iter div4  (dividend_3, i_divisor, remainder_3, quotient_3, dividend_4, remainder_4, quotient_4);
   lc4_divider_one_iter div5  (dividend_4, i_divisor, remainder_4, quotient_4, dividend_5, remainder_5, quotient_5);
   lc4_divider_one_iter div6  (dividend_5, i_divisor, remainder_5, quotient_5, dividend_6, remainder_6, quotient_6);
   lc4_divider_one_iter div7  (dividend_6, i_divisor, remainder_6, quotient_6, dividend_7, remainder_7, quotient_7);
   lc4_divider_one_iter div8  (dividend_7, i_divisor, remainder_7, quotient_7, dividend_8, remainder_8, quotient_8);
   lc4_divider_one_iter div9  (dividend_8, i_divisor, remainder_8, quotient_8, dividend_9, remainder_9, quotient_9);
   lc4_divider_one_iter div10 (dividend_9, i_divisor, remainder_9, quotient_9, dividend_10, remainder_10, quotient_10);
   lc4_divider_one_iter div11 (dividend_10, i_divisor, remainder_10, quotient_10, dividend_11, remainder_11, quotient_11);
   lc4_divider_one_iter div12 (dividend_11, i_divisor, remainder_11, quotient_11, dividend_12, remainder_12, quotient_12);
   lc4_divider_one_iter div13 (dividend_12, i_divisor, remainder_12, quotient_12, dividend_13, remainder_13, quotient_13);
   lc4_divider_one_iter div14 (dividend_13, i_divisor, remainder_13, quotient_13, dividend_14, remainder_14, quotient_14);
   lc4_divider_one_iter div15 (dividend_14, i_divisor, remainder_14, quotient_14, dividend_15, remainder_15, quotient_15);
   lc4_divider_one_iter div16 (dividend_15, i_divisor, remainder_15, quotient_15, dividend_16, remainder_16, quotient_16);

endmodule