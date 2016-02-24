/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 * TODO: Contributions of each group member to this file
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    // State of the zedboard switches, LCD and LEDs
    // You are welcome to use the Zedboard's LCD number display and LEDs
    // for debugging purposes, but it isn't terribly useful.  Ditto for
    // reading the switch positions from the Zedboard

    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [15:0] seven_segment_data, // Data to display to the Zedboard LCD
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );
   

   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/

    // From the decoder
    wire [2:0] r1sel;
    wire r1re;
    wire [2:0] r2sel;
    wire r2re;
    wire nzp_we;
    wire [2:0] wsel;
    wire regfile_we;
    wire select_pc_plus_one;
    wire is_load;
    wire is_store;
    wire is_branch;
    wire is_control_insn;
  
    lc4_decoder decoder (i_cur_insn, r1sel, r1re, r2sel, r2re, wsel, regfile_we, nzp_we, select_pc_plus_one, is_load, is_store, is_branch, is_control_insn);
    
    wire [15:0] o_alu;
    // Reg_File
    wire [15:0] o_rs_data;
    wire [15:0] o_rt_data;
    // MUST BE COMPUTED, SET TO ZER0 FOR NOW (really mux of alu or mem)
    wire [15:0] i_wdata = ( is_load  == 0 ) ? ( o_alu ) : ( 16'h0000 ); // need to change this for mem
    
    lc4_regfile regfile (clk, gwe, rst, r1sel, o_rs_data, r2sel, o_rt_data, wsel, i_wdata, regfile_we);
    
    // ALU
    lc4_alu alu (i_cur_insn, pc, o_rs_data, o_rt_data, o_alu);
    
    // MEMORY
    assign o_dmem_towrite = ( is_load ) ? o_dmem_towrite :
                            ( is_store ) ? o_rt_data  :              
                            16'h0000;  // 0 if no load / store??? CHECK THIS
    assign o_dmem_addr = ( is_load | is_store ) ? o_alu : 16'h0000;
    assign o_dmem_we = is_store;
      
    // BRANCH LOGIC
    wire [2:0] curr_nzp = 3'b001; // TODO: change this
    wire o_branch = !( ( i_cur_insn[11:9] & curr_nzp ) == 3'b000);
    
    
    // PC_MUX
    assign next_pc = ( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
    
    assign o_cur_pc = pc;
   // assign next_pc = pc + 1; // for now with ALU, not forever
    
    
    // Set test wires to correct outputs
    assign  test_stall = 2'b00;          // Testbench: is this a stall cycle? (don't compare the test values)
    assign  test_cur_pc = pc;               // Testbench: program counter
    assign  test_cur_insn = i_cur_insn;     // Testbench: instruction bits
    assign  test_regfile_we = regfile_we;   // Testbench: register file write enable
    assign  test_regfile_wsel = wsel;       // Testbench: which register to write in the register file 
    assign  test_regfile_data = i_wdata;    // Testbench: value to write into the register file
    assign  test_nzp_we = nzp_we;           // Testbench: NZP condition codes write enable
    
    assign  test_nzp_new_bits[2] = i_wdata[15];   // Testbench: value to write to NZP bits (Needs to be computed)
    assign  test_nzp_new_bits[1] = (i_wdata == 16'h0000);
    assign  test_nzp_new_bits[0] = (!i_wdata[15]) & (!test_nzp_new_bits[1]) ; // wrong in our schematic
    
    assign  test_dmem_we = o_dmem_we;            // Testbench: data memory write enable
    assign  test_dmem_addr = o_dmem_addr;      // Testbench: address to read/write memory
    assign  test_dmem_data = o_dmem_towrite; // Testbench: value read/writen from/to memory
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

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
endmodule
