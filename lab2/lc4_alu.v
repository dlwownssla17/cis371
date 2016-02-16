/* INSERT NAME AND PENNKEY HERE */

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

`define zero 1'd0
`define one 1'd1

module lc4_barrel_shift(input  wire [15:0] i_num,
                        input  wire [3:0]  shift,
                        input  wire        to_left,
                        input  wire        is_arithmetic,
                        output wire [15:0] o_num);
                        
   wire [15:0] num_shift_3, num_shift_2, num_shift_1;
   
   assign num_shift_3 = ~shift[3]     ? i_num :
                        to_left       ? {i_num[7:0], {8{`zero}}} :
                        is_arithmetic ? {{8{i_num[15]}}, i_num[15:8]} : {{8{`zero}}, i_num[15:8]};
   assign num_shift_2 = ~shift[2]     ? num_shift_3 :
                        to_left       ? {num_shift_3[11:0], {4{`zero}}} :
                        is_arithmetic ? {{4{i_num[15]}}, num_shift_3[15:4]} : {{4{`zero}}, num_shift_3[15:4]};
   assign num_shift_1 = ~shift[1]     ? num_shift_2 :
                        to_left       ? {num_shift_2[13:0], {2{`zero}}} :
                        is_arithmetic ? {{2{i_num[15]}}, num_shift_2[15:2]} : {{2{`zero}}, num_shift_2[15:2]};
   assign o_num       = ~shift[0]     ? num_shift_1 :
                        to_left       ? {num_shift_1[14:0], `zero} :
                        is_arithmetic ? {i_num[15], num_shift_1[15:1]} : {`zero, num_shift_1[15:1]};
   
endmodule

module lc4_branch_op(input  wire [15:0] i_insn,
                     input  wire [15:0] i_pc,
                     output wire [15:0] o_result);
                  
   assign o_result = i_pc + `one + {{7{i_insn[8]}}, i_insn[8:0]};
   
endmodule

module lc4_arith_op(input  wire [15:0] i_insn,
                    input  wire [15:0] i_r1data,
                    input  wire [15:0] i_r2data,
                    input  wire [15:0] quotient,
                    output wire [15:0] o_result);
                      
   assign o_result = (i_insn[5:3] == 3'b000) ? i_r1data + i_r2data :
                     (i_insn[5:3] == 3'b001) ? i_r1data * i_r2data :
                     (i_insn[5:3] == 3'b010) ? i_r1data - i_r2data :
                     (i_insn[5:3] == 3'b011) ? quotient : i_r1data + {{11{i_insn[4]}}, i_insn[4:0]};
   
endmodule

module lc4_compare_op(input  wire [15:0] i_insn,
                      input  wire [15:0] i_r1data,
                      input  wire [15:0] i_r2data,
                      output wire [15:0] o_result);
                   
   wire [15:0] gt = 16'h0001;
   wire [15:0] lt = 16'hffff;
   wire [15:0] eq = 16'h0000;
   wire [16:0] r1data_u = {`zero, i_r1data};
   wire [16:0] r2data_u = {`zero, i_r2data};
   wire [7:0] imm_7_u = {`zero, i_insn[6:0]};
   wire r1_r2_same_sign = i_r1data[15] == i_r2data[15];
   wire [15:0] r1_imm_7_diff = i_r1data - {{9{i_insn[6]}}, i_insn[6:0]};
   
   wire [15:0] cmp_result   = (i_r1data == i_r2data)   ? eq :
                              r1_r2_same_sign          ? cmpu_result :
                              i_r1data[15]             ? lt : gt;
   wire [15:0] cmpu_result  = (r1data_u == r2data_u)   ? eq :
                              (r1data_u < r2data_u)    ? lt : gt;
   wire [15:0] cmpi_result  = (r1_imm_7_diff == `zero) ? eq :
                              r1_imm_7_diff[15]        ? lt : gt;
   wire [15:0] cmpiu_result = (r1data_u == imm_7_u)    ? eq :
                              (r1data_u < imm_7_u)     ? lt : gt;
   
   assign o_result = (i_insn[8:7] == 2'b00) ? cmp_result :
                     (i_insn[8:7] == 2'b01) ? cmpu_result :
                     (i_insn[8:7] == 2'b10) ? cmpi_result : cmpiu_result;
   
endmodule

module lc4_jsr_op(input  wire [15:0] i_insn,
                  input  wire [15:0] i_pc,
                  input  wire [15:0] i_r1data,
                  output wire [15:0] o_result);
                  
   wire [15:0] pc_msb_masked = i_pc & 16'h8000;
   wire [15:0] imm_11_offset;
               
   assign o_result = ~i_insn[11] ? i_r1data : pc_msb_masked | imm_11_offset;
   
   lc4_barrel_shift shift ({{5{`zero}}, i_insn[10:0]}, 4'b0100, `one, `zero, imm_11_offset);
   
endmodule

module lc4_logic_op(input  wire [15:0] i_insn,
                    input  wire [15:0] i_r1data,
                    input  wire [15:0] i_r2data,
                    output wire [15:0] o_result);
                 
   assign o_result = (i_insn[5:3] == 3'b000) ? i_r1data & i_r2data :
                     (i_insn[5:3] == 3'b001) ? ~i_r1data :
                     (i_insn[5:3] == 3'b010) ? i_r1data | i_r2data :
                     (i_insn[5:3] == 3'b011) ? i_r1data ^ i_r2data : i_r1data & {{11{i_insn[4]}}, i_insn[4:0]};
   
endmodule

module lc4_memory_op(input  wire [15:0] i_insn,
                     input  wire [15:0] i_r1data,
                     output wire [15:0] o_result);
                     
   assign o_result = i_r1data + {{10{i_insn[5]}}, i_insn[5:0]};
   
endmodule

module lc4_rti_op(input  wire [15:0] i_r1data,
                  output wire [15:0] o_result);
                  
   assign o_result = i_r1data;
   
endmodule

module lc4_const_op(input  wire [15:0] i_insn,
                    output wire [15:0] o_result);
                    
   assign o_result = {{7{i_insn[8]}}, i_insn[8:0]};
   
endmodule

module lc4_shift_op(input  wire [15:0] i_insn,
                    input  wire [15:0] i_r1data,
                    input  wire [15:0] i_r2data,
                    input  wire [15:0] remainder,
                    output wire [15:0] o_result);
                    
   wire [15:0] shift_result;
   wire to_left = i_insn[5:4] == 2'b00;
   wire is_arithmetic = i_insn[5:4] == 2'b01;
   
   assign o_result = (i_insn[5:4] == 2'b11) ? remainder : shift_result;
   
   lc4_barrel_shift shift (i_r1data, i_insn[3:0], to_left, is_arithmetic, shift_result);
   
endmodule

module lc4_jmp_op(input  wire [15:0] i_insn,
                  input  wire [15:0] i_pc,
                  input  wire [15:0] i_r1data,
                  output wire [15:0] o_result);
                  
   assign o_result = ~i_insn[11] ? i_r1data : i_pc + `one + {{5{i_insn[10]}}, i_insn[10:0]};
   
endmodule

module lc4_hiconst_op(input  wire [15:0] i_insn,
                      input  wire [15:0] i_r1data,
                      output wire [15:0] o_result);
                      
   wire [15:0] r1data_masked = i_r1data & 16'h00ff;
   wire [15:0] imm_8_shifted;
   
   assign o_result = r1data_masked | imm_8_shifted;
   
   lc4_barrel_shift shift ({{8{`zero}}, i_insn[7:0]}, 4'b1000, `one, `zero, imm_8_shifted);
   
endmodule

module lc4_trap_op(input  wire [15:0] i_insn,
                   output wire [15:0] o_result);
                   
   assign o_result = 16'h8000 | i_insn[7:0];
   
endmodule

module lc4_alu(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);
   
   wire [15:0] remainder, quotient;
   wire [15:0] branch_result, arith_result, compare_result, jsr_result, logic_result, memory_result,
               rti_result, const_result, shift_result, jmp_result, hiconst_result, trap_result;
   
   assign o_result = (i_insn[15:12] == 4'b0000) ? branch_result :
                     (i_insn[15:12] == 4'b0001) ? arith_result :
                     (i_insn[15:12] == 4'b0010) ? compare_result :
                     (i_insn[15:12] == 4'b0100) ? jsr_result :
                     (i_insn[15:12] == 4'b0101) ? logic_result :
                     (i_insn[15:12] == 4'b0110 |
                      i_insn[15:12] == 4'b0111) ? memory_result :
                     (i_insn[15:12] == 4'b1000) ? rti_result :
                     (i_insn[15:12] == 4'b1001) ? const_result :
                     (i_insn[15:12] == 4'b1010) ? shift_result :
                     (i_insn[15:12] == 4'b1100) ? jmp_result :
                     (i_insn[15:12] == 4'b1101) ? hiconst_result :
                     (i_insn[15:12] == 4'b1111) ? trap_result : 16'd0;
   
   lc4_divider    div         (i_r1data, i_r2data, remainder, quotient);
   lc4_branch_op  branch_res  (i_insn, i_pc, branch_result);
   lc4_arith_op   arith_res   (i_insn, i_r1data, i_r2data, quotient, arith_result);
   lc4_compare_op compare_res (i_insn, i_r1data, i_r2data, compare_result);
   lc4_jsr_op     jsr_res     (i_insn, i_pc, i_r1data, jsr_result);
   lc4_logic_op   logic_res   (i_insn, i_r1data, i_r2data, logic_result);
   lc4_memory_op  memory_res  (i_insn, i_r1data, memory_result);
   lc4_rti_op     rti_res     (i_r1data, rti_result);
   lc4_const_op   const_res   (i_insn, const_result);
   lc4_shift_op   shift_res   (i_insn, i_r1data, i_r2data, remainder, shift_result);
   lc4_jmp_op     jmp_res     (i_insn, i_pc, i_r1data, jmp_result);
   lc4_hiconst_op hiconst_res (i_insn, i_r1data, hiconst_result);
   lc4_trap_op    trap_res    (i_insn, trap_result);
   
endmodule