`timescale 1ns / 1ps

`define EOF 32'hFFFF_FFFF
`define NEWLINE 10
`define NULL 0

`include "set_testcase.v"

module test_lc4_superscalar_v;

`include "include/lc4_prettyprint_errors.v"

   integer     input_file, output_file, errors, linenum;
   integer     num_cycles;
   integer     num_A_exec, num_A_branch_stall, num_A_load_stall, num_A_stall_ss;
   integer     num_B_exec, num_B_branch_stall, num_B_load_stall, num_B_stall_ss;

   integer     next_instruction, pipe_A;

   integer     num_stalls_in_a_row;

   // Inputs
   reg         clk;
   reg         rst;
   wire [15:0] imem1_out, imem2_out;
   wire [15:0] dmem_out;

   // Outputs
   wire [15:0] imem1_addr, imem2_addr;
   wire [15:0] dmem_addr;
   wire [15:0] dmem_data;
   wire        dmem_we;

   wire [1:0]  test_stall_A,        test_stall_B;         // Testbench: is this is stall cycle? (don't compare the test values)
   wire [15:0] test_cur_pc_A,       test_cur_pc_B;        // Testbench: program counter
   wire [15:0] test_cur_insn_A,     test_cur_insn_B;      // Testbench: instruction bits
   wire        test_regfile_we_A,   test_regfile_we_B;    // Testbench: register file write enable
   wire [2:0]  test_regfile_wsel_A, test_regfile_wsel_B;  // Testbench: which register to write in the register file
   wire [15:0] test_regfile_data_A, test_regfile_data_B;  // Testbench: value to write into the register file
   wire        test_nzp_we_A,       test_nzp_we_B;        // Testbench: NZP condition codes write enable
   wire [2:0]  test_nzp_new_bits_A, test_nzp_new_bits_B;  // Testbench: value to write to NZP bits
   wire        test_dmem_we_A,      test_dmem_we_B;       // Testbench: data memory write enable
   wire [15:0] test_dmem_addr_A,    test_dmem_addr_B;     // Testbench: address to write memory
   wire [15:0] test_dmem_data_A,    test_dmem_data_B;     // Testbench: value to write memory

   reg [15:0]  test_pc;          // Testbench: program counter
   reg [15:0]  test_insn;        // Testbench: instruction bits
   reg         test_regfile_we;  // Testbench: register file write enable
   reg [2:0]   test_regfile_wsel; // Testbench: which register to write in the register file
   reg [15:0]  test_regfile_data;  // Testbench: value to write into the register file
   reg         test_nzp_we;      // Testbench: NZP condition codes write enable
   reg [2:0]   test_nzp_new_bits;      // Testbench: value to write to NZP bits
   reg         test_dmem_we;     // Testbench: data memory write enable
   reg [15:0]  test_dmem_addr;   // Testbench: address to write memory
   reg [15:0]  test_dmem_data;  // Testbench: value to write memory

   reg [15:0]  verify_pc;
   reg [15:0]  verify_insn;
   reg         verify_regfile_we;
   reg [2:0]   verify_regfile_wsel;
   reg [15:0]  verify_regfile_data;
   reg         verify_nzp_we;
   reg [2:0]   verify_nzp_new_bits;
   reg         verify_dmem_we;
   reg [15:0]  verify_dmem_addr;
   reg [15:0]  verify_dmem_data;
   reg [15:0]  file_status;

   wire [15:0] vout_dummy;  // video out


   always #5 clk <= ~clk;

   // Produce gwe and other we signals using same modules as lc4_system
   wire        i1re, i2re, dre, gwe;
   lc4_we_gen we_gen(.clk(clk),
		             .i1re(i1re),
		             .i2re(i2re),
		             .dre(dre),
		             .gwe(gwe));


   // Data and video memory block
   lc4_memory memory (.idclk(clk),
		              .i1re(i1re),
		              .i2re(i2re),
		              .dre(dre),
		              .gwe(gwe),
		              .rst(rst),
                      .i1addr(imem1_addr),
		              .i2addr(imem2_addr),
                      .i1out(imem1_out),
		              .i2out(imem2_out),
                      .daddr(dmem_addr),
		              .din(dmem_data),
                      .dout(dmem_out),
                      .dwe(dmem_we),
                      .vclk(1'b0),
                      .vaddr(16'h0000),
                      .vout(vout_dummy));


   // Instantiate the Unit Under Test (UUT)
   lc4_processor proc_inst(.clk(clk),
			               .rst(rst),
			               .gwe(gwe),
			               .o_cur_pc(imem1_addr),
			               .i_cur_insn_A(imem1_out),
			               .i_cur_insn_B(imem2_out),
			               .o_dmem_addr(dmem_addr),
			               .i_cur_dmem_data(dmem_out),
			               .o_dmem_we(dmem_we),
			               .o_dmem_towrite(dmem_data),
			               .test_stall_A(test_stall_A),
			               .test_stall_B(test_stall_B),
			               .test_cur_pc_A(test_cur_pc_A),
			               .test_cur_pc_B(test_cur_pc_B),
			               .test_cur_insn_A(test_cur_insn_A),
			               .test_cur_insn_B(test_cur_insn_B),
			               .test_regfile_we_A(test_regfile_we_A),
			               .test_regfile_we_B(test_regfile_we_B),
			               .test_regfile_wsel_A(test_regfile_wsel_A),
			               .test_regfile_wsel_B(test_regfile_wsel_B),
			               .test_regfile_data_A(test_regfile_data_A),
			               .test_regfile_data_B(test_regfile_data_B),
			               .test_nzp_we_A(test_nzp_we_A),
			               .test_nzp_we_B(test_nzp_we_B),
			               .test_nzp_new_bits_A(test_nzp_new_bits_A),
			               .test_nzp_new_bits_B(test_nzp_new_bits_B),
			               .test_dmem_we_A(test_dmem_we_A),
			               .test_dmem_we_B(test_dmem_we_B),
			               .test_dmem_addr_A(test_dmem_addr_A),
			               .test_dmem_addr_B(test_dmem_addr_B),
			               .test_dmem_data_A(test_dmem_data_A),
			               .test_dmem_data_B(test_dmem_data_B),
			               .switch_data(8'd0)
                           );

   assign imem2_addr = imem1_addr + 16'd1;

   // always #5 $display("%d: %d %d %d %h", $time, clk, gwe, rst, test_pc);

   initial begin
      // Initialize Inputs
      clk = 0;
      rst = 1;
      linenum = 0;
      errors = 0;
      num_cycles = 0;
      num_A_exec = 0;
      num_B_exec = 0;
      num_A_branch_stall = 0;
      num_B_branch_stall = 0;
      num_A_load_stall = 0;
      num_B_load_stall = 0;
      num_A_stall_ss = 0;
      num_B_stall_ss = 0;
      file_status = 10;

      num_stalls_in_a_row = 0;

      // open the test inputs
      input_file = $fopen(`INPUT_FILE, "r");
      if (input_file == `NULL) begin
         $display("Error opening file: %s", `INPUT_FILE);
         $finish;
      end

      // open the output file
`ifdef OUTPUT
      output_file = $fopen(`OUTPUT_FILE, "w");
      if (output_file == `NULL) begin
         $display("Error opening file: %s", `OUTPUT_FILE);
         $finish;
      end
`endif


      #80
        // Wait for global reset to finish
        rst = 0;
      #32;

      pipe_A = 1; // true
      while (10 == $fscanf(input_file, "%h %b %h %h %h %h %h %h %h %h",
                           verify_pc,
                           verify_insn,
                           verify_regfile_we,
                           verify_regfile_wsel,
                           verify_regfile_data,
                           verify_nzp_we,
                           verify_nzp_new_bits,
                           verify_dmem_we,
                           verify_dmem_addr,
                           verify_dmem_data)) begin

         linenum = linenum + 1;

         if (linenum % 10000 == 0) begin
            $display("Instruction number: %d", linenum);
         end

         if (output_file) begin
            $fdisplay(output_file, "%h %b %h %h %h %h %h %h %h %h",
                      verify_pc,
                      verify_insn,
                      verify_regfile_we,
                      verify_regfile_wsel,
                      verify_regfile_data,
                      verify_nzp_we,
                      verify_nzp_new_bits,
                      verify_dmem_we,
                      verify_dmem_addr,
                      verify_dmem_data);
         end

         next_instruction = 0;  // false
         while (!next_instruction) begin

            if (pipe_A) begin
               if (test_stall_A === 2'd0) begin
                  num_A_exec = num_A_exec + 1;

                  next_instruction = 1;  // true

                  test_pc           = test_cur_pc_A;
                  test_insn         = test_cur_insn_A;
                  test_regfile_we   = test_regfile_we_A;
                  test_regfile_wsel = test_regfile_wsel_A;
                  test_regfile_data = test_regfile_data_A;
                  test_nzp_we       = test_nzp_we_A;
                  test_nzp_new_bits = test_nzp_new_bits_A;
                  test_dmem_we      = test_dmem_we_A;
                  test_dmem_addr    = test_dmem_addr_A;
                  test_dmem_data    = test_dmem_data_A;
                  num_stalls_in_a_row = 0;
               end else begin
                  num_stalls_in_a_row = num_stalls_in_a_row + 1;
               end

               if (test_stall_A === 2'd1) begin
                  num_A_stall_ss = num_A_stall_ss + 1;
               end

               if (test_stall_A === 2'd2) begin
                  num_A_branch_stall = num_A_branch_stall + 1;
               end

               if (test_stall_A === 2'd3) begin
                  num_A_load_stall = num_A_load_stall + 1;
               end
            end

            if (!pipe_A) begin
               if (test_stall_B === 2'd0) begin
                  num_B_exec = num_B_exec + 1;

                  next_instruction = 1;  // true

                  test_pc           = test_cur_pc_B;
                  test_insn         = test_cur_insn_B;
                  test_regfile_we   = test_regfile_we_B;
                  test_regfile_wsel = test_regfile_wsel_B;
                  test_regfile_data = test_regfile_data_B;
                  test_nzp_we       = test_nzp_we_B;
                  test_nzp_new_bits = test_nzp_new_bits_B;
                  test_dmem_we      = test_dmem_we_B;
                  test_dmem_addr    = test_dmem_addr_B;
                  test_dmem_data    = test_dmem_data_B;
                  num_stalls_in_a_row = 0;
               end else begin
                  num_stalls_in_a_row = num_stalls_in_a_row + 1;
               end

               if (test_stall_B === 2'd1) begin
                  num_B_stall_ss = num_B_stall_ss + 1;
               end

               if (test_stall_B === 2'd2) begin
                  num_B_branch_stall = num_B_branch_stall + 1;
               end

               if (test_stall_B === 2'd3) begin
                  num_B_load_stall = num_B_load_stall + 1;
               end
            end

            if (num_stalls_in_a_row > 10) begin
               $display("Error at line %d: your pipeline has stalled for more than 10 cycles in a row, which should never happen.", linenum);
               $finish;
            end

            if (next_instruction) begin
               // Check it before fetching the next instruction

               // pc
               if (verify_pc !== test_pc) begin
                  $display( "Error at line %d: pc should be %h (but was %h) [pipe %s]",
                            linenum, verify_pc, test_pc, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // insn
               if (verify_insn !== test_insn) begin
                  $write( "Error at line %d: insn should be %h (", linenum, verify_insn);
                  pinstr(verify_insn);
                  $write(") but was %h (", test_insn);
                  pinstr(test_insn);
                  $display(") [pipe %s]", pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // regfile_we
               if (verify_regfile_we !== test_regfile_we) begin
                  $display( "Error at line %d: regfile_we should be %h (but was %h) [pipe %s]",
                            linenum, verify_regfile_we, test_regfile_we, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // regfile_wsel
               if (verify_regfile_we && verify_regfile_wsel !== test_regfile_wsel) begin
                  $display( "Error at line %d: regfile_wsel should be %h (but was %h) [pipe %s]",
                            linenum, verify_regfile_wsel, test_regfile_wsel, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // regfile_data
               if (verify_regfile_we && verify_regfile_data !== test_regfile_data) begin
                  $display( "Error at line %d: regfile_data should be %h (but was %h) [pipe %s]",
                            linenum, verify_regfile_data, test_regfile_data, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // verify_nzp_we
               if (verify_nzp_we !== test_nzp_we) begin
                  $display( "Error at line %d: nzp_we should be %h (but was %h) [pipe %s]",
                            linenum, verify_nzp_we, test_nzp_we, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // verify_nzp_new_bits
               if (verify_nzp_we && verify_nzp_new_bits !== test_nzp_new_bits) begin
                  $display( "Error at line %d: nzp_new_bits should be %h (but was %h) [pipe %s]",
                            linenum, verify_nzp_new_bits, test_nzp_new_bits, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // verify_dmem_we
               if (verify_dmem_we !== test_dmem_we) begin
                  $display( "Error at line %d: dmem_we should be %h (but was %h) [pipe %s]",
                            linenum, verify_dmem_we, test_dmem_we, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // dmem_addr
               if (verify_dmem_addr !== test_dmem_addr) begin
                  $display( "Error at line %d: dmem_addr should be %h (but was %h) [pipe %s]",
                            linenum, verify_dmem_addr, test_dmem_addr, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

               // dmem_data
               if (verify_dmem_data !== test_dmem_data) begin
                  $display( "Error at line %d: dmem_data should be %h (but was %h) [pipe %s]",
                            linenum, verify_dmem_data, test_dmem_data, pipe_A ? "A" : "B");
                  errors = errors + 1;
                  $finish;
               end

            end

            // Advanced to the next cycle
            if (!pipe_A) begin
               num_cycles = num_cycles + 1;
	           #40;  // Next cycle
            end

            pipe_A = !pipe_A;  // toggle which pipe to look at next

         end // while (!next_instruction)

      end // while (10 == $fscanf(input_file, "%h %b %h %h %h %h %h %h %h %h",...


      if (input_file) $fclose(input_file);
      if (output_file) $fclose(output_file);
      $display("Simulation finished: %d test cases %d errors [%s]", linenum, errors, `INPUT_FILE);

      if (linenum != num_cycles) begin
         $display("  Instructions:         %d", linenum);
         $display("  Total Cycles:         %d", num_cycles);
         $display("  CPI x 1000: %d", 1000 * num_cycles / linenum);
         $display("  IPC x 1000: %d", 1000 * linenum / num_cycles);

         $display("  A Execution:          %d", num_A_exec);
	     $display("  A Branch stalls:      %d", num_A_branch_stall);
	     $display("  A Load stalls:        %d", num_A_load_stall);
      end

      if (num_B_exec != 0) begin
         $display("  A Superscalar stalls: %d", num_A_stall_ss);
         $display("  B Execution:          %d", num_B_exec);
         $display("  B Branch stalls:      %d", num_B_branch_stall);
	     $display("  B Load stalls:        %d", num_B_load_stall);
         $display("  B Superscalar stalls: %d", num_B_stall_ss);

      end

      $finish;
   end // initial begin

endmodule
