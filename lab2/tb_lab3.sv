module tb_crv_randomize_lab3_p2;

// Parameters
localparam int WIDTH = 16;
localparam int INSTR_LEN = 20;
localparam int ADDR = 5;
localparam int PROG_LEN =100;

  logic clk, reset, go;
  logic instruction_done;
  logic [WIDTH-1:0] result;
  logic [WIDTH-1:0] expected = 0;

  // For memory interface
  logic        wr_en;
  logic [ADDR-1:0]  wr_addr;
  logic [INSTR_LEN-1:0] wr_data;

  // Local variables for loops
  int i,j;

// Temporary signals for coverage
  logic [7:0] a_sig, b_sig;
  logic [3:0] opcode_sig;

  // Instantiate DUT
  top  #(.WIDTH(WIDTH),.INSTR_LEN(INSTR_LEN),.ADDR(ADDR),.PROG_LEN(PROG_LEN)) dut (
    .clk(clk),
    .reset(reset),
    .go(go),
    .done(instruction_done),
    .result(result),

    // memory connections
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;



  // ===== CRV Instruction Class =====
  class instr;
    rand bit [3:0] opcode;    // 4-bit opcode
    rand bit [7:0] a, b;      // 8-bit operands
    bit [3:0] prev_opcode;
    bit [7:0] prev_a, prev_b;

 constraint c_opcode_range { opcode inside {[4'b0001:4'b0011], 4'b1011, 4'b1111 }; }
  
// Comment (2b) Add Contraint 1 here: Define a constraint named unique_operands to generate different a and b values at each iteration. 




// Comment (2c) Add Contraint 2 here: Using the implication operator ->, define a constraint named small_operands 
// which will constrain, “If a and b are both small (<25), then the opcode is changed to ADD”.





// Comment (2d) Write a soft constraint that b should be greater than a and can be overridden 
// using inline constraint to make it a > b (See randomize() function in (2e)





    // ------------------------------------------------------------------
    // VALID pre_randomize() records values, does not modify random vars 
    // ------------------------------------------------------------------

    function void pre_randomize();
        prev_opcode = opcode;
        prev_a      = a;
        prev_b      = b;

        $display("[pre_randomize] Prev opcode=%04b a=%0d b=%0d",
                 prev_opcode, prev_a, prev_b);
    endfunction

    // --------------------------------------------------------------------------
    // VALID post_randomize(), override if identical to previous opcode, a, and b
    // --------------------------------------------------------------------------
    function void post_randomize();
        $display("[post_randomize] New opcode=%04b a=%0d b=%0d",
                 opcode, a, b);

        if ((opcode == prev_opcode) && (a == prev_a) && (b == prev_b)) begin 
          
            // Comment(2f) Insert code here to override the values of 'a' and 'b'
            //     by adding 1 to each (a = a+1; b = b+1); 
		
            $display("[post_randomize] WARNING: same result repeated!");
					// changing the values of a and b, becuase it is repeated concecutively.
	      $display ("changing the values of a=%d and b=%d",a,b);
	    end
		
    endfunction


  endclass

  instr instr_obj;

  // --------------------------------------------------
  // Reference Model 
  // --------------------------------------------------
  function automatic bit [WIDTH-1:0] ref_model(input [3:0] opcode, input [7:0] a, input [7:0] b);
    int x = a, y = b;
    case (opcode)
      4'b0001: ref_model = a + b;
      4'b0010: ref_model = a - b;
      4'b0011: ref_model = a * b;
      4'b1011: begin
        while (y != 0) begin
          int temp = y;
          y = x % y;
          x = temp;
        end
        ref_model = x;
      end
      default: ref_model = 16'd0;
    endcase
  endfunction

  // Task to write to memory
  task mem_write(input [ADDR-1:0] addr, input [INSTR_LEN-1:0] data);
    begin
      @(posedge clk);
      go <= 1'b1;
      wr_en   <= 1;
      wr_addr <= addr;
      wr_data <= data;
      @(posedge clk);
      wr_en   <= 0;
      go <= 1'b0;
    end
  endtask

 // =============================
  // Functional Coverage
  // =============================
  covergroup cg_inputs;
    coverpoint a_sig {
      bins a [] = {[0:255]};
      
    }

    coverpoint b_sig {
      bins b [] = {[0:255]};
      
    }
    coverpoint opcode_sig {
      bins valid_opcode []= {4'b0001,4'b0010,4'b0011,4'b1011,4'b1111}; 
      bins Invalid_opcode []= {0,[4:10],[12:14]};
      
    }
	
// Comment (2a) Define a cross coverage for opreand a and b here. (Hint: use a_sig,b_sig)


  endgroup

  cg_inputs cov_inst = new();

  
   
    
  // Test Sequence
  initial begin
    wr_en   <= 0; 
    wr_addr <= 0; 
    wr_data <= 0;
    reset   <= 1;
    go <= 0;
    #20 reset <= 0;

    $display("=== Starting CRV Testbench ===");
    
    // object creation
    instr_obj = new();

    //Randomization
     for (int i = 0; i < PROG_LEN; i++) begin

        // Normal randomization for first (PROG_LEN - 5) iterations
        if (i < PROG_LEN - 5) begin
            assert(instr_obj.randomize()) // Comment (2e) Modify this statement to override 
                                          //  soft constraint (2d) and make a > b
              else $fatal("Randomization failed!");

      

        end 
        else begin
            // ------------------------------
            // Last 5 iterations: REPEAT LAST
            // ------------------------------
            $display("[INFO] Forcing repetition at iter %0d", i);

            assert(instr_obj.randomize() with {
                opcode == prev_opcode;
                a      == prev_a;
                b      == prev_b;
            }) else $fatal("Forced repetition failed!");
        end

	 // Assign to signals for coverage
      a_sig = instr_obj.a;
      b_sig = instr_obj.b;
      opcode_sig = instr_obj.opcode;

	cov_inst.sample();

      // Show generated values to students
      $display("Displaying Memory Contents Iter=%0d | Opcode=%04b | A=%0d | B=%0d", 
                i, instr_obj.opcode, instr_obj.a, instr_obj.b);

      // Write randomized instruction to memory
      mem_write(i, {instr_obj.opcode, instr_obj.a, instr_obj.b});

      // Wait for DUT to complete
      @(posedge clk)
      wait(instruction_done);  

      expected = ref_model(instr_obj.opcode, instr_obj.a, instr_obj.b);

      //Comparison expected with Dut Result
      if (result !== expected) begin
        $error("FAIL | Opcode=%04b A=%0d B=%0d | Got=%0d, Expected=%0d",
                instr_obj.opcode, instr_obj.a, instr_obj.b, result, expected);
      end else begin
        $display("Result_PASS | Opcode=%04b A=%0d B=%0d | Result=%0d",
                 instr_obj.opcode, instr_obj.a, instr_obj.b, result);

                  $display(".............................");
      end
    end

    #10;
    $display("=== Test Finished ===");
    $finish;
  end


endmodule
