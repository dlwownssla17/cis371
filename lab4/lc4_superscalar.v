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

module lc4_processor(input wire         clk,             // main cock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [15:0] seven_segment_data,  // value to display on zedboard's two-digit display
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

`include "include/lc4_prettyprint_errors.v"

   /***  YOUR CODE HERE ***/
 // IMPLEMENT STALL AND FLUSH LOGIC NEXT WEEK
 wire [1:0] is_stall = 0;
 wire is_flush ; //= 0; 
 wire [1:0] f_stall = 0;
 wire load_to_use_stall;
 wire superscalar_stall;

 wire           x_is_load;


 /*********************************************************************************************************************/
 /******************************************************  FETCH  ******************************************************/
 /*********************************************************************************************************************/
 /********** FETCH STAGE PREAMBLE **********/
 wire [15:0] f_pc;
 wire [15:0] f_temp_pc;
 wire [15:0] f_insnA;
 wire [15:0] f_insnB;
 wire [15:0] next_pc;

 Nbit_reg #(16, 16'h8200) f_pc_reg       (.in(next_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  

 /********** FETCH STAGE IMPLEMENTATION **********/
 assign next_pc =   ( load_to_use_stall )   ? f_pc      : 
                    ( superscalar_stall )   ? f_pc+1    :
                    ( is_flush )            ? o_aluA    : 
                      f_pc + 2;  // idk if it should come from A or B
                    
 assign f_insnA =   ( is_stall || load_to_use_stall )   ?   (d_insnA)   :
                    ( superscalar_stall )               ?   (d_insnB)   : 
                    ( is_flush )                        ?   (16'h0000)  : 
                      i_cur_insn_A;
                    
 assign f_insnB =   ( is_stall || load_to_use_stall )   ? (d_insnB)         :
                    ( superscalar_stall )               ? (i_cur_insn_A)    : 
                    ( is_flush )                        ? (16'h0000)        : 
                      i_cur_insn_B;

 // wire [15:0] f_temp_pc = (is_stall || load_to_use_stall) ? d_pc : f_pc;
 assign o_cur_pc = f_pc;
 // Eh
 assign f_temp_pc = ( superscalar_stall )   ? d_pc + 1  : f_pc;
 
 /*********************************************************************************************************************/
 /****************************************************** DECODE  ******************************************************/
 /*********************************************************************************************************************/
 /********** DECODE STAGE PREAMBLE **********/
 wire [15:0] d_pc;
 wire [15:0] d_insnA; 
 wire [15:0] d_insnB;    
 wire [1:0] d_stallA;
 wire [1:0] d_stallB;

 /** FROM FETCH TO DECODE **/    
 Nbit_reg #(16, 16'h0000)    d_pc_reg    (.in(f_temp_pc), .out(d_pc), .clk(clk), .we(!(is_stall || load_to_use_stall)), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    d_insn_regA  (.in(f_insnA), .out(d_insnA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    d_insn_regB  (.in(f_insnB), .out(d_insnB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // MIGHT NEED TO CHANGE THIS NEXT WEEK

 wire [1:0] f_temp_stall = ( is_flush ) ? 2'd2 : f_stall;

 Nbit_reg #(2, 2'b10)        d_stall_regA (.in(f_temp_stall), .out(d_stallA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(2, 2'b10)        d_stall_regB (.in(f_temp_stall), .out(d_stallB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // From the decoder
 wire [2:0]     d_r1selA;
 wire [2:0]     d_r2selA;
 wire           d_r1reA;
 wire           d_r2reA;
 wire           d_select_pc_plus_oneA;
 wire           d_is_loadA;
 wire           d_is_storeA;
 wire           d_is_control_insnA;
 wire           d_is_branchA;
 wire [2:0]     d_wselA;
 wire           d_regfile_weA;
 wire           d_nzp_weA;
 wire [0:15]    d_ort_dataA;
 wire [0:15]    d_ors_dataA;
 wire [0:15]    d_rt_dataA;
 wire [0:15]    d_rs_dataA;

 wire [2:0]     d_r1selB;
 wire [2:0]     d_r2selB;
 wire           d_r1reB;
 wire           d_r2reB;
 wire           d_select_pc_plus_oneB;
 wire           d_is_loadB;
 wire           d_is_storeB;
 wire           d_is_control_insnB;
 wire           d_is_branchB;
 wire [2:0]     d_wselB;
 wire           d_regfile_weB;
 wire           d_nzp_weB;
 wire [0:15]    d_ort_dataB;
 wire [0:15]    d_ors_dataB;
 wire [0:15]    d_rt_dataB;
 wire [0:15]    d_rs_dataB;


 /********** DECODE STAGE IMPLEMENTATION **********/
 lc4_decoder decoderA (d_insnA, d_r1selA, d_r1reA, d_r2selA, d_r2reA, d_wselA, d_regfile_weA, d_nzp_weA, d_select_pc_plus_oneA, d_is_loadA, d_is_storeA, d_is_branchA, d_is_control_insnA);
 lc4_decoder decoderB (d_insnB, d_r1selB, d_r1reB, d_r2selB, d_r2reB, d_wselB, d_regfile_weB, d_nzp_weB, d_select_pc_plus_oneB, d_is_loadB, d_is_storeB, d_is_branchB, d_is_control_insnB);
 lc4_regfile_ss regfile (.clk(clk), .gwe(gwe), .rst(rst), 
            .i_rs_A(d_r1selA), .o_rs_data_A(d_ors_dataA), .i_rt_A(d_r2selA), .o_rt_data_A(d_ort_dataA), 
            .i_rs_B(d_r1selB), .o_rs_data_B(d_ors_dataB), .i_rt_B(d_r2selB), .o_rt_data_B(d_ort_dataB), 
            .i_rd_A(w_wselA), .i_rd_B(w_wselB), .i_wdata_A(w_resultA), .i_wdata_B(w_resultB), 
            .i_rd_we_A(w_regfile_weA), .i_rd_we_B(w_regfile_weB) );

 assign d_rs_dataA =  d_ors_dataA; // (d_r1selA == w_wselA && w_regfile_weA) ? w_resultA : --> unnecissary due to regfile logic
 assign d_rt_dataA =  d_ort_dataA; // (d_r2selA == w_wselA && w_regfile_weA) ? w_resultA : 
 
 assign d_rs_dataB = d_ors_dataB; // (d_r1selB == w_wselB && w_regfile_weB) ? w_resultB : 
 assign d_rt_dataB = d_ort_dataB; // (d_r2selB == w_wselB && w_regfile_weB) ? w_resultB : 
 
 // Maybe doesn't cover branching or single-cycle load_to_use superscalar stall
 // i dont think first case of superscalar stall is necissary : d_wselA == d_wselB && d_regfile_weA && d_regfile_weB
 assign superscalar_stall =  ( ( ((d_wselA == d_r1selB) && d_r1reB) || ((d_wselA == d_r2selB) && d_r2reB)) && d_regfile_weA ); //d_wselA == d_wselB && d_regfile_weA && d_regfile_weB || 
 assign load_to_use_stall = 1'd0; // ( x_is_load ) && (( d_r1sel == x_wsel && d_r1re ) || (( d_r2sel == x_wsel && d_r2re ) && (!d_is_store)));
 
 /*********************************************************************************************************************/
 /****************************************************** EXECUTE ******************************************************/
 /*********************************************************************************************************************/
 /********** EXECUTE STAGE PREAMBLE **********/
 wire [15:0]    x_pc;
 wire [15:0]    x_insnA;
 wire [2:0]     x_r1selA;
 wire [2:0]     x_r2selA;
 wire           x_r1reA;
 wire           x_r2reA;
 wire           x_select_pc_plus_oneA;
 wire           x_is_loadA;
 wire           x_is_storeA;
 wire           x_is_control_insnA;
 wire           x_is_branchA;
 wire [2:0]     x_wselA;
 wire           x_regfile_weA;
 wire           x_nzp_weA;
 wire [15:0]    x_r1dataA;
 wire [15:0]    x_r2dataA;

 wire [15:0]    x_insnB;
 wire [2:0]     x_r1selB;
 wire [2:0]     x_r2selB;
 wire           x_r1reB;
 wire           x_r2reB;
 wire           x_select_pc_plus_oneB;
 wire           x_is_loadB;
 wire           x_is_storeB;
 wire           x_is_control_insnB;
 wire           x_is_branchB;
 wire [2:0]     x_wselB;
 wire           x_regfile_weB;
 wire           x_nzp_weB;
 wire [15:0]    x_r1dataB;
 wire [15:0]    x_r2dataB;

 wire [1:0]     x_stallA;
 wire [1:0]     x_stallB;

 wire [15:0] d_temp_insnA = ( d_stallA ) ? (x_insnA) : 
                            (is_flush || load_to_use_stall) ? (16'h0000) : d_insnA;

 wire [15:0] d_temp_insnB = ( d_stallB ) ? (x_insnB) : 
                            ( is_flush || load_to_use_stall || superscalar_stall ) ? (16'h0000) : d_insnB;

 wire xt_r1reA =                (is_flush || load_to_use_stall) ? 1'b0 : d_r1reA;
 wire xt_r2reA =                (is_flush || load_to_use_stall) ? 1'b0 : d_r2reA;
 wire xt_select_pc_plus_oneA  = (is_flush || load_to_use_stall) ? 1'b0 : d_select_pc_plus_oneA;
 wire xt_is_loadA =             (is_flush || load_to_use_stall) ? 1'b0 : d_is_loadA;
 wire xt_is_storeA =            (is_flush || load_to_use_stall) ? 1'b0 : d_is_storeA;
 wire xt_is_control_insnA =     (is_flush || load_to_use_stall) ? 1'b0 : d_is_control_insnA;
 wire xt_is_branchA =           (is_flush || load_to_use_stall) ? 1'b0 : d_is_branchA;

 wire xt_regfile_weA =          (is_flush || load_to_use_stall) ? 1'b0 : d_regfile_weA;
 wire xt_nzp_weA =              (is_flush || load_to_use_stall) ? 1'b0 : d_nzp_weA;

 wire xt_r1reB =                (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_r1reB;
 wire xt_r2reB =                (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_r2reB;
 wire xt_select_pc_plus_oneB  = (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_select_pc_plus_oneB;
 wire xt_is_loadB =             (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_is_loadB;
 wire xt_is_storeB =            (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_is_storeB;
 wire xt_is_control_insnB =     (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_is_control_insnB;
 wire xt_is_branchB =           (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_is_branchB;

 wire xt_regfile_weB =          (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_regfile_weB;
 wire xt_nzp_weB =              (is_flush || load_to_use_stall || superscalar_stall) ? 1'b0 : d_nzp_weB;

 /** FROM DECODE TO EXECUTE **/ 
 Nbit_reg #(16, 16'h0000)    x_pc_reg                     (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_insn_regA                  (.in(d_temp_insnA), .out(x_insnA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r1sel_regA                 (.in(d_r1selA), .out(x_r1selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r2sel_regA                 (.in(d_r2selA), .out(x_r2selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r1re_regA                  (.in(xt_r1reA), .out(x_r1reA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r2re_regA                  (.in(xt_r2reA), .out(x_r2reA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_select_pc_plus_one_regA    (.in(xt_select_pc_plus_oneA), .out(x_select_pc_plus_oneA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_load_regA               (.in(xt_is_loadA), .out(x_is_loadA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_store_regA              (.in(xt_is_storeA), .out(x_is_storeA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_control_insn_regA       (.in(xt_is_control_insnA), .out(x_is_control_insnA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_branch_regA             (.in(xt_is_branchA), .out(x_is_branchA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_wsel_regA                  (.in(d_wselA), .out(x_wselA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_regfile_we_regA            (.in(xt_regfile_weA), .out(x_regfile_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_nzp_we_regA                (.in(xt_nzp_weA), .out(x_nzp_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r1data_regA                (.in(d_rs_dataA), .out(x_r1dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r2data_regA                (.in(d_rt_dataA), .out(x_r2dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    x_insn_regB                  (.in(d_temp_insnB), .out(x_insnB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r1sel_regB                 (.in(d_r1selB), .out(x_r1selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r2sel_regB                 (.in(d_r2selB), .out(x_r2selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r1re_regB                  (.in(xt_r1reB), .out(x_r1reB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r2re_regB                  (.in(xt_r2reB), .out(x_r2reB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_select_pc_plus_one_regB    (.in(xt_select_pc_plus_oneB), .out(x_select_pc_plus_oneB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_load_regB               (.in(xt_is_loadB), .out(x_is_loadB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_store_regB              (.in(xt_is_storeB), .out(x_is_storeB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_control_insn_regB       (.in(xt_is_control_insnB), .out(x_is_control_insnB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_branch_regB             (.in(xt_is_branchB), .out(x_is_branchB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_wsel_regB                  (.in(d_wselB), .out(x_wselB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_regfile_we_regB            (.in(xt_regfile_weB), .out(x_regfile_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_nzp_we_regB                (.in(xt_nzp_weB), .out(x_nzp_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r1data_regB                (.in(d_rs_dataB), .out(x_r1dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r2data_regB                (.in(d_rt_dataB), .out(x_r2dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 
 wire [1:0] d_temp_stallA = ( load_to_use_stall ) ? 2'd3 : 
                            ( is_flush ) ?          2'd2 : 
                              d_stallA;
                              
 Nbit_reg #(2, 2'b10)         x_stall_regA                 (.in(d_temp_stallA), .out(x_stallA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 wire [1:0] d_temp_stallB = ( load_to_use_stall )   ? 2'd3 : 
                            ( is_flush )            ? 2'd2 : 
                            ( superscalar_stall )   ? 2'd1 :
                              d_stallB;
                              
 Nbit_reg #(2, 2'b10)         x_stall_regB                 (.in(d_temp_stallB), .out(x_stallB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


 wire [2:0] curr_nzp; // FROM REGFILE

 /********** EXECUTE STAGE IMPLEMENTATION **********/

 wire [15:0] x_pc_plus_oneA = x_pc+1;
 wire [15:0] x_pc_plus_oneB = x_pc+1;
 wire [15:0] o_aluA;
 wire [15:0] o_aluB;
 // BYPASSING FOR A:
 wire [15:0] alu_1A;
 wire [15:0] alu_1B;
 wire [15:0] alu_2A;
 wire [15:0] alu_2B;
 assign alu_1A =    ( (x_r1selA == m_wselB) && (m_regfile_weB) )   ? m_oresultB    : 
                    ( (x_r1selA == m_wselA) && (m_regfile_weA) )   ? m_oresultA    : 
                    ( (x_r1selA == w_wselB) && (w_regfile_weB) )   ? w_resultB     :
                    ( (x_r1selA == w_wselA) && (w_regfile_weA) )   ? w_resultA     : x_r1dataA;

 assign alu_2A =    ( (x_r2selA == m_wselB) && (m_regfile_weB) )   ? m_oresultB    : 
                    ( (x_r2selA == m_wselA) && (m_regfile_weA) )   ? m_oresultA    : 
                    ( (x_r2selA == w_wselB) && (w_regfile_weB) )   ? w_resultB     :
                    ( (x_r2selA == w_wselA) && (w_regfile_weA) )   ? w_resultA     : x_r2dataA;

// BYPASSING FOR B:
 assign alu_1B =    ( (x_r1selB == m_wselB) && (m_regfile_weB) )   ? m_oresultB    : 
                    ( (x_r1selB == m_wselA) && (m_regfile_weA) )   ? m_oresultA    : 
                    ( (x_r1selB == w_wselB) && (w_regfile_weB) )   ? w_resultB     :
                    ( (x_r1selB == w_wselA) && (w_regfile_weA) )   ? w_resultA     : x_r1dataB;

 assign alu_2B =    ( (x_r2selB == m_wselB) && (m_regfile_weB) )   ? m_oresultB    : 
                    ( (x_r2selB == m_wselA) && (m_regfile_weA) )   ? m_oresultA    : 
                    ( (x_r2selB == w_wselB) && (w_regfile_weB) )   ? w_resultB     :
                    ( (x_r2selB == w_wselA) && (w_regfile_weA) )   ? w_resultA     : x_r2dataB;

 // ALU
 lc4_alu aluA (x_insnA, x_pc, alu_1A, alu_2A, o_aluA);
 lc4_alu aluB (x_insnB, x_pc+1, alu_1B, alu_2B, o_aluB);
 wire [15:0] x_oresultA = ( x_select_pc_plus_oneA ) ? ( x_pc_plus_oneA ) : ( o_aluA ); 
 wire [15:0] x_oresultB = ( x_select_pc_plus_oneB ) ? ( x_pc_plus_oneB ) : ( o_aluB ); 

 
 // branch in A
  wire [15:0] x_temp_insnB = ( is_flushA ) ? (16'h0000) : x_insnB;
 
  wire mt_r1reB =                (is_flushA ) ? 1'b0 : x_r1reB;
  wire mt_r2reB =                (is_flushA ) ? 1'b0 : x_r2reB;
  wire mt_is_loadB =             (is_flushA ) ? 1'b0 : x_is_loadB;
  wire mt_is_storeB =            (is_flushA ) ? 1'b0 : x_is_storeB;
  wire mt_is_control_insnB =     (is_flushA ) ? 1'b0 : x_is_control_insnB;
  wire mt_is_branchB =           (is_flushA ) ? 1'b0 : x_is_branchB;
 
  wire mt_regfile_weB =          (is_flushA ) ? 1'b0 : x_regfile_weB;
  wire mt_nzp_weB =              (is_flushA ) ? 1'b0 : x_nzp_weB;

  wire [1:0] x_temp_stallB = ( is_flushA ) ? 2'd2 : x_stallB;
 
 // PC_MUX
 //    assign  next_pc = 16'h0000;//( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
 //assign o_cur_pc = pc;

 // COMPUTE EXECUTE NZP BITS    
 wire [2:0] x_nzp_bitsA;
 assign x_nzp_bitsA[2] = x_oresultA[15];
 assign x_nzp_bitsA[1] = (x_oresultA == 16'h0000);
 assign x_nzp_bitsA[0] = (!x_oresultA[15]) & (!x_nzp_bitsA[1]);
 
  wire [2:0] x_nzp_bitsB;
 assign x_nzp_bitsB[2] = x_oresultB[15];
 assign x_nzp_bitsB[1] = (x_oresultB == 16'h0000);
 assign x_nzp_bitsB[0] = (!x_oresultB[15]) & (!x_nzp_bitsB[1]);
 
 
 // BRANCH LOGIC
  wire [2:0] br_nzpA; 
  assign br_nzpA = 
     ( m_nzp_weB ) ? ( m_nzp_bitsB ) : 
     ( m_nzp_weA ) ? ( m_nzp_bitsA ) :
     ( w_nzp_weB ) ? ( w_nzp_bitsB ) :
     ( w_nzp_weA ) ? ( w_nzp_bitsA ) : ( curr_nzp );
  
  wire [2:0] br_nzpB; // what happens when you branch at B?
  assign br_nzpB = ( x_nzp_weA ) ? ( x_nzp_bitsA ) : br_nzpA;
  
   wire o_branchA = (( x_wselA & br_nzpA ) != 3'b000);  // this is wrong
   wire o_branchB = (( x_wselB & br_nzpB ) != 3'b000); // this is wrong

   wire is_flushA = (( o_branchA & x_is_branchA ) | x_is_control_insnA);
   wire is_flushB = (( o_branchB & x_is_branchB ) | x_is_control_insnB);
   
   assign is_flush = (is_flushA || is_flushB); // if we are taking a branch, flush old instrucions -- wrong with superscalar

 wire [15:0] x_temp_r2dataA = (x_is_storeA && x_r2selA == m_wselA && m_regfile_weA) ? w_resultA : x_r2dataA;
 wire [15:0] x_temp_r2dataB = (x_is_storeB && x_r2selB == m_wselB && m_regfile_weB) ? w_resultB : x_r2dataB;


 /*********************************************************************************************************************/
 /****************************************************** MEMORY  ******************************************************/
 /*********************************************************************************************************************/
 /********** MEMORY STAGE PREAMBLE **********/
 wire [15:0]    m_pc;
 wire [15:0]    m_insnA;
 wire [2:0]     m_r1selA;
 wire [2:0]     m_r2selA;
 wire [2:0]     m_wselA;
 wire           m_is_loadA;
 wire           m_is_storeA;
 wire           m_regfile_weA;
 wire           m_nzp_weA;
 wire [15:0]    m_r1dataA;
 wire [15:0]    m_r2dataA;
 wire [2:0]     m_nzp_bitsA;
 wire [15:0]    m_oresultA;
 wire [15:0]    m_oaluA;
 wire [15:0]    m_wdataA;
 wire [1:0]     m_stallA;
 
 wire [15:0]    m_insnB;
 wire [2:0]     m_r1selB;
 wire [2:0]     m_r2selB;
 wire [2:0]     m_wselB;
 wire           m_is_loadB;
 wire           m_is_storeB;
 wire           m_regfile_weB;
 wire           m_nzp_weB;
 wire [15:0]    m_r1dataB;
 wire [15:0]    m_r2dataB;
 wire [2:0]     m_nzp_bitsB;
 wire [15:0]    m_oresultB;
 wire [15:0]    m_oaluB;
 wire [15:0]    m_wdataB;
 wire [1:0]     m_stallB;

 /** FROM EXECUTE TO MEMORY **/
 Nbit_reg #(16, 16'h0000)    m_pc_reg                   (.in(x_pc), .out(m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    m_insn_regA                 (.in(x_insnA), .out(m_insnA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r1sel_regA                (.in(x_r1selA), .out(m_r1selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r2sel_regA                (.in(x_r2selA), .out(m_r2selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_load_regA              (.in(x_is_loadA), .out(m_is_loadA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_store_regA             (.in(x_is_storeA), .out(m_is_storeA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_wsel_regA                 (.in(x_wselA), .out(m_wselA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_regfile_we_regA           (.in(x_regfile_weA), .out(m_regfile_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_nzp_we_regA               (.in(x_nzp_weA), .out(m_nzp_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r1data_regA               (.in(alu_1A), .out(m_r1dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r2data_regA               (.in(alu_2A), .out(m_r2dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_nzp_regA                  (.in(x_nzp_bitsA), .out(m_nzp_bitsA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    m_insn_regB                 (.in(x_temp_insnB), .out(m_insnB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r1sel_regB                (.in(x_r1selB), .out(m_r1selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r2sel_regB                (.in(x_r2selB), .out(m_r2selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_load_regB              (.in(mt_is_loadB), .out(m_is_loadB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_store_regB             (.in(mt_is_storeB), .out(m_is_storeB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_wsel_regB                 (.in(x_wselB), .out(m_wselB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_regfile_we_regB           (.in(mt_regfile_weB), .out(m_regfile_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_nzp_we_regB               (.in(mt_nzp_weB), .out(m_nzp_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r1data_regB               (.in(alu_1B), .out(m_r1dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r2data_regB               (.in(alu_2B), .out(m_r2dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_nzp_regB                  (.in(x_nzp_bitsB), .out(m_nzp_bitsB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


 // MIGHT NEED TO CHANGE THIS NEXT WEEK 
 Nbit_reg #(2, 2'b10)        m_stall_regA                (.in(x_stallA), .out(m_stallA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(2, 2'b10)        m_stall_regB                (.in(x_temp_stallB), .out(m_stallB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 /** SPECIAL FROM EXECUTE **/
 Nbit_reg #(16, 16'h0000)    m_oresult_regA              (.in(x_oresultA), .out(m_oresultA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_oalu_regA                 (.in(o_aluA), .out(m_oaluA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    m_oresult_regB              (.in(x_oresultB), .out(m_oresultB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_oalu_regB                 (.in(o_aluB), .out(m_oaluB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // Nbit_reg #(3, 3'b000) mem_reg (.in(nzp_new_bits), .out(curr_nzp), .clk(clk), .we(m_nzp_we), .gwe(gwe), .rst(rst));  

 /********** MEMORY STAGE IMPLEMENTATION **********/ 
 wire [15:0]    m_dmem_data; 
 wire [15:0]    m_dmem_addr;
 wire [15:0]    m_dmem_towrite;
 wire           m_dmem_we;
 
 // Needs work next week
 // 0 if no load / store??? CHECK THIS
 assign o_dmem_towrite = ( m_is_storeA ) ? ( ( w_regfile_weA && ( w_wselA == m_r2selA ) ) ? w_resultA : m_r2dataA ) : 16'h0000;
 assign o_dmem_addr = ( m_is_loadA | m_is_storeA ) ? m_oaluA : 16'h0000;
 assign o_dmem_we = m_is_storeA;
 assign m_dmem_towrite = o_dmem_towrite;
 assign m_dmem_data = ( m_is_loadA ) ? i_cur_dmem_data : 16'h0000;
 assign m_dmem_addr = o_dmem_addr;
 assign m_dmem_we = o_dmem_we;
 
 /*************************************************************************************************************************/
 /****************************************************** WRITEBACK   ******************************************************/
 /*************************************************************************************************************************/
 /********** WRITEBACK STAGE PREAMBLE **********/
 wire [15:0]    w_pc;
 wire [15:0]    w_insnA;
 wire [2:0]     w_r1selA;
 wire [2:0]     w_r2selA;
 wire [2:0]     w_wselA;
 wire           w_is_loadA;
 wire           w_regfile_weA;
 wire           w_nzp_weA;
 wire [15:0]    w_r1dataA;
 wire [15:0]    w_r2dataA;
 wire [15:0]    w_wdataA;
 wire [15:0]    w_oresultA;
 wire [15:0]    w_resultA;
 wire [2:0]     w_nzp_bitsA;

 wire [15:0]    w_insnB;
 wire [2:0]     w_r1selB;
 wire [2:0]     w_r2selB;
 wire [2:0]     w_wselB;
 wire           w_is_loadB;
 wire           w_regfile_weB;
 wire           w_nzp_weB;
 wire [15:0]    w_r1dataB;
 wire [15:0]    w_r2dataB;
 wire [15:0]    w_wdataB;
 wire [15:0]    w_oresultB;
 wire [15:0]    w_resultB;
 wire [2:0]     w_nzp_bitsB;

 wire [15:0]    w_dmem_data; 
 wire [15:0]    w_dmem_towrite; 
 wire [15:0]    w_dmem_addr;
 wire           w_dmem_we;
 wire [1:0]     w_stallA;
 wire [1:0]     w_stallB;


 /** FROM MEMORY TO WRITEBACK **/
 Nbit_reg #(16, 16'h0000)    w_pc_reg                   (.in(m_pc), .out(w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 Nbit_reg #(16, 16'h0000)    w_insn_regA                (.in(m_insnA), .out(w_insnA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r1sel_regA               (.in(m_r1selA), .out(w_r1selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r2sel_regA               (.in(m_r2selA), .out(w_r2selA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_is_load_regA             (.in(m_is_loadA), .out(w_is_loadA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_wsel_regA                (.in(m_wselA), .out(w_wselA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_regfile_we_regA          (.in(m_regfile_weA), .out(w_regfile_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_nzp_we_regA              (.in(m_nzp_weA), .out(w_nzp_weA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r1data_regA              (.in(m_r1dataA), .out(w_r1dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r2data_regA              (.in(m_r2dataA), .out(w_r2dataA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_nzp_regA                 (.in(m_nzp_bitsA), .out(w_nzp_bitsA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
 Nbit_reg #(16, 16'h0000)    w_insn_regB                (.in(m_insnB), .out(w_insnB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r1sel_regB               (.in(m_r1selB), .out(w_r1selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r2sel_regB               (.in(m_r2selB), .out(w_r2selB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_is_load_regB             (.in(m_is_loadB), .out(w_is_loadB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_wsel_regB                (.in(m_wselB), .out(w_wselB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_regfile_we_regB          (.in(m_regfile_weB), .out(w_regfile_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_nzp_we_regB              (.in(m_nzp_weB), .out(w_nzp_weB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r1data_regB              (.in(m_r1dataB), .out(w_r1dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r2data_regB              (.in(m_r2dataB), .out(w_r2dataB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_nzp_regB                 (.in(m_nzp_bitsB), .out(w_nzp_bitsB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
 Nbit_reg #(2, 2'b10)        w_stall_regA                (.in(m_stallA), .out(w_stallA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(2, 2'b10)        w_stall_regB                (.in(m_stallB), .out(w_stallB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 /** SPECIAL FROM MEMORY **/
 Nbit_reg #(16, 16'h0000)   w_oresult_regA               (.in(m_oresultA), .out(w_oresultA), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_oresult_regB               (.in(m_oresultB), .out(w_oresultB), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_data_reg             (.in(m_dmem_data), .out(w_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_towrite_reg          (.in(m_dmem_towrite), .out(w_dmem_towrite), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_addr_reg             (.in(m_dmem_addr), .out(w_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)        w_dmem_we_reg               (.in(m_dmem_we), .out(w_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
 assign w_resultA = ( w_is_loadA ) ? w_dmem_data : w_oresultA;
 assign w_resultB = ( w_is_loadB ) ? w_dmem_data : w_oresultB;

 wire [2:0] w_temp_nzp_bitsA = w_nzp_bitsA;
 /*
 assign w_temp_nzp_bitsA[2] = ( w_is_loadA ) ? (w_resultA[15]) : (w_nzp_bitsA[2]);
 assign w_temp_nzp_bitsA[1] = ( w_is_loadA ) ? (w_resultA == 16'h0000) : w_nzp_bitsA[1];
 assign w_temp_nzp_bitsA[0] = ( w_is_loadA ) ? ((!w_resultA[15]) & (!w_temp_nzp_bitsA[1])) : w_nzp_bitsA[0];
 */
 wire [2:0] w_temp_nzp_bitsB = w_nzp_bitsB;
 /*
 assign w_temp_nzp_bitsB[2] = ( w_is_loadB ) ? (w_resultB[15]) : (w_nzp_bitsB[2]);
 assign w_temp_nzp_bitsB[1] = ( w_is_loadB ) ? (w_resultB == 16'h0000) : w_nzp_bitsB[1];
 assign w_temp_nzp_bitsB[0] = ( w_is_loadB ) ? ((!w_resultB[15]) & (!w_temp_nzp_bitsB[1])) : w_nzp_bitsB[0];
 */
  wire [2:0] w_nzp_into_reg = ( w_nzp_weB ) ? w_temp_nzp_bitsB : w_temp_nzp_bitsA;
 
 /********** WRITEBACK STAGE IMPLEMENTATION **********/    
 // Assign curr_nzp from B pipe
 Nbit_reg #(3, 3'b000) nzp_reg (.in(w_nzp_into_reg), .out(curr_nzp), .clk(clk), .we(w_nzp_weA || w_nzp_weB), .gwe(gwe), .rst(rst));    
 // Write to regfile (see code in the decode stage)
 // BRANCH LOGIC
 //    wire [2:0] curr_nzp; // TODO: change this
 //    wire o_branch = !( ( i_cur_insn[11:9] & curr_nzp ) == 3'b000);

 // PC_MUX
 //    assign  next_pc = 16'h0000;//( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
 //assign o_cur_pc = pc;


 // Set test wires to correct outputs
 assign test_stall_A = w_stallA;                        // is this a stall cycle?  (0: no stall,
 assign test_stall_B = w_stallB;                        // 1: pipeline stall, 2: branch stall, 3: load stall)
 assign test_cur_pc_A = w_pc;                           // program counter       
 assign test_cur_pc_B = w_pc + 1;
 assign test_cur_insn_A = w_insnA;                      // instruction bits                                      
 assign test_cur_insn_B = w_insnB;                                                              
 assign test_regfile_we_A = w_regfile_weA;   			// register file write-enable                      
 assign test_regfile_we_B = w_regfile_weB;                                                      
 assign test_regfile_wsel_A = w_wselA;                  // which register to write                              
 assign test_regfile_wsel_B = w_wselB;                                                          
 assign test_regfile_data_A = w_resultA;  // (d_wselA == d_wselB && d_regfile_weA && d_regfile_weB) ? w_resultB :               // data to write to register file                      
 assign test_regfile_data_B = w_resultB;     
 
 assign test_nzp_we_A = w_nzp_weA;                      // nzp register write enable                      
 assign test_nzp_we_B = w_nzp_weB;                                                     
/*
 assign test_nzp_new_bits_A[2] = w_temp_nzp_bitsA[2]; 		// new nzp bits
 assign test_nzp_new_bits_A[1] = w_temp_nzp_bitsA[1];
 assign test_nzp_new_bits_A[0] = w_temp_nzp_bitsA[0];
 assign test_nzp_new_bits_B[2] = w_temp_nzp_bitsB[2];
 assign test_nzp_new_bits_B[1] = w_temp_nzp_bitsB[1];
 assign test_nzp_new_bits_B[0] = w_temp_nzp_bitsB[0];
 EXCLUDING LOAD NZP FOR RIGHT NOW*/
 
 assign test_nzp_new_bits_A = w_nzp_bitsA;
 assign test_nzp_new_bits_B = w_nzp_bitsB;

 assign test_dmem_we_A = w_dmem_we;                 // data memory write enable                                        
 assign test_dmem_we_B = w_dmem_we;                                                                         
 assign test_dmem_addr_A = w_dmem_addr;             // address to read/write from/to memory                            
 assign test_dmem_addr_B = w_dmem_addr;                                                                       
 assign test_dmem_data_A = 16'h0000;                // data to read/write from/to memory                               
 assign test_dmem_data_B = 16'h0000;                                                                       
 //assign  test_dmem_data = w_is_load ? w_dmem_data : w_dmem_towrite; // Testbench: value read/writen from/to memory



   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */

      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);
      
 //     `ifndef NDEBUG
       always @(posedge gwe) begin

      $write("superscalar_stall: %b", superscalar_stall); $display(" ");
      $write("is flush? %b A?: %b B? %b", is_flush, is_flushA, is_flushB); $display(" ");
      $write("is flush-- stall A?: %b B? %b", w_stallA, w_stallB); $display(" ");


      $write("f_pcA: %h i_cur_insnA: %h (", f_pc, i_cur_insn_A); pinstr(i_cur_insn_A); $display(")");
      $write("f_pcB: %h i_cur_insnB: %h (", f_pc, i_cur_insn_B); pinstr(i_cur_insn_B); $display(")");
      
      $write("f_pcA: %h f_insnA: %h (", f_pc, f_insnA); pinstr(f_insnA); $display(")");
      $write("f_pcB: %h f_insnB: %h (", f_pc, f_insnB); pinstr(f_insnB); $display(")");

      $write("d_pcA: %h d_insnA: %h (", d_pc, d_insnA); pinstr(d_insnA); $display(")");
      $write("d_pcB: %h d_insnB: %h (", d_pc, d_insnB); pinstr(d_insnB); $display(")");
      
      $write("x_pcA: %h x_insnA: %h (", x_pc, x_insnA); pinstr(x_insnA); $display(")");
      $write("x_pcB: %h x_insnB: %h (", x_pc, x_insnB); pinstr(x_insnB); $display(")");

      $write("m_pcA: %h m_insnA: %h (", m_pc, m_insnA); pinstr(m_insnA); $display(")");
      $write("m_pcB: %h m_insnB: %h (", m_pc, m_insnB); pinstr(m_insnB); $display(")");

      $write("w_pcA: %h w_insnA: %h (", w_pc, w_insnA); pinstr(w_insnA); $display(")");
      $write("w_pcB: %h w_insnB: %h (", w_pc, w_insnB); pinstr(w_insnB); $display(")");
      $write("w_regfileA: %h w_regfileB: %h ", w_resultA, w_resultB); 
      $write(" ");
/*  
      $display("flush: %d load_to_use: %d", is_flush, load_to_use_stall);
      // $display("%d,M_DATA is %h, M_R1 is %h, M_R2 is %h", $time, m_dmem_data, m_r1data, m_r2data);
      $display("%d,W_REG is %h, W_FROM_DATA is %h, W_TO_WRITE %h, W_ALU is %h, %b", $time, w_result, w_dmem_data, w_dmem_towrite, w_oresult, w_is_load);
      $display("");

*/
      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      $display();
   end
 //   `endif
endmodule
