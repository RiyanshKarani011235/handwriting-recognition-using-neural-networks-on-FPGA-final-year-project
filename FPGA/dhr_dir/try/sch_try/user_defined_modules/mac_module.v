`include "pulse_generator.v"
module mac_module(
   input wire clk,
   input wire reset,   //synchronous
   input wire [17:0] data_a,data_b,
   input wire a_valid,b_valid,
   output wire p_ready,
   output wire [47:0] data_p
   );

   wire clock_enable;
   reg [47:0] PCIN;
   reg [7:0] OPMODE;

   reg [1:0] count; 

   reg next_signal;
   wire valid_inputs;
   reg p_ready_pulse_generator;

   assign valid_inputs = a_valid & b_valid;

	// DSP48A1: 48-bit Multi-Functional Arithmetic Block
   //          Spartan-6
   // Xilinx HDL Language Template, version 14.7
	
   DSP48A1 #(
      .A0REG(0),              // First stage A input pipeline register (0/1)
      .A1REG(1),              // Second stage A input pipeline register (0/1)
      .B0REG(0),              // First stage B input pipeline register (0/1)
      .B1REG(1),              // Second stage B input pipeline register (0/1)
      .CARRYINREG(0),         // CARRYIN input pipeline register (0/1)
      .CARRYINSEL("OPMODE5"), // Specify carry-in source, "CARRYIN" or "OPMODE5" 
      .CARRYOUTREG(0),        // CARRYOUT output pipeline register (0/1)
      .CREG(0),               // C input pipeline register (0/1)
      .DREG(0),               // D pre-adder input pipeline register (0/1)
      .MREG(0),               // M pipeline register (0/1)
      .OPMODEREG(1),          // Enable=1/disable=0 OPMODE input pipeline registers
      .PREG(1),               // P output pipeline register (0/1)
      .RSTTYPE("SYNC")        // Specify reset type, "SYNC" or "ASYNC" 
   )
   DSP48A1_inst (
      // Cascade Ports: 18-bit (each) output: Ports to cascade from one DSP48 to another
         // .BCOUT(bcout),           // 18-bit output: B port cascade output                                               UNCONNECTED
         // .PCOUT(PCOUT),           // 48-bit output: P cascade output (if used, connect to PCIN of another DSP48A1)      UNCONNECTED
      // Data Ports: 1-bit (each) output: Data input and output ports
         // .CARRYOUT(CARRYOUT),     // 1-bit output: carry output (if used, connect to CARRYIN pin of another             UNCONNECTED
                                  // DSP48A1)

         // .CARRYOUTF(CARRYOUTF),   // 1-bit output: fabric carry output                                                  UNCONNECTED
         // .M(data_m),                   // 36-bit output: fabric multiplier data output                                  UNCONNECTED
         .P(data_p),                   // 48-bit output: data output                                                       OUTPUT
      // Cascade Ports: 48-bit (each) input: Ports to cascade from one DSP48 to another
         .PCIN(48'b0),             // 48-bit input: P cascade input (if used, connect to PCOUT of another DSP48A1)         PRE-DEFINED
      // Control Input Ports: 1-bit (each) input: Clocking and operation mode
         .CLK(clk),               // 1-bit input: clock Input                                                              INPUT
         .OPMODE(OPMODE),         // 8-bit input: operation mode Input                                                     DEFINED
      // Data Ports: 18-bit (each) input: Data input and output ports
         .A(data_a),                   // 18-bit input: A data Input                                                       INPUT
         .B(data_b),                   // 18-bit input: B data input (connected to fabric or BCOUT of adjacent DSP48A1)    INPUT
         // .C(data_c),                   // 48-bit input: C data input                                                    UNCONNECTED
         // .CARRYIN(CARRYIN),       // 1-bit input: carry input signal (if used, connect to CARRYOUT pin of another       UNCONNECTED
                                  // DSP48A1)

         // .D(data_d),                   // 18-bit input: B pre-adder data Input                                          UNCONNECTED
      // Reset/Clock Enable Input Ports: 1-bit (each) input: Reset and enable input ports
         .CEA(clock_enable),      // 1-bit input: active high clock enable input for A registers                           DEFINED
         .CEB(clock_enable),      // 1-bit input: active high clock enable input for B registers                           DEFINED
         .CEC(1'b1),               // 1-bit input: active high clock enable input for C registers                          PRE-DEFINED
         .CECARRYIN(1'b1),   // 1-bit input: active high clock enable input for CARRYIN registers                          PRE-DEFINED
         .CED(1'b1),               // 1-bit input: active high clock enable input for D registers                          PRE-DEFINED
         .CEM(clock_enable),      // 1-bit input: active high clock enable input for multiplier registers                  DEFINED
         .CEOPMODE(1'b1),     // 1-bit input: active high clock enable input for OPMODE registers                          PRE-DEFINED
         .CEP(clock_enable),      // 1-bit input: active high clock enable input for P registers                           DEFINED
         .RSTA(reset),            // 1-bit input: reset input for A pipeline registers                                     DEFINED
         .RSTB(reset),            // 1-bit input: reset input for B pipeline registers                                     DEFINED
         .RSTC(reset),            // 1-bit input: reset input for C pipeline registers                                     DEFINED
         .RSTCARRYIN(reset),      // 1-bit input: reset input for CARRYIN pipeline registers                               DEFINED
         .RSTD(reset),            // 1-bit input: reset input for D pipeline registers                                     DEFINED
         .RSTM(reset),            // 1-bit input: reset input for M pipeline registers                                     DEFINED
         .RSTOPMODE(reset),       // 1-bit input: reset input for OPMODE pipeline registers                                DEFINED
         .RSTP(reset)             // 1-bit input: reset input for P pipeline registers                                     DEFINED
   );
   // End of DSP48A1_inst instantiation
	
   pulse_generator #(
      .PULSE_WIDTH(32'd1)
      ) p5(
      .clk(clk),
      .generate_pulse_when_high(valid_inputs), // pulse generator
      .pulse(clock_enable) // generates a PULSE on p_ready
      );

   pulse_generator #(
      .PULSE_WIDTH(32'd1)
      ) p4(
      .clk(clk),
      .generate_pulse_when_high(valid_inputs), // pulse generator
      .pulse(p_ready) // generates a PULSE on p_ready
      );   

   initial begin
      p_ready_pulse_generator = 0;
      count = 0;
      // clock_enable <= 0;
      OPMODE[1:0]  <= 1;      // Use multiplier product
      OPMODE[3:2]  <= 2;      // Use the P out signal
      OPMODE[4]    <= 0;      // Pre Adder ----> Not Needed
      OPMODE[5]    <= 0;      // Force Carry
      OPMODE[6]    <= 0;      // Pre Adder ----> Add 
      OPMODE[7]    <= 0;      // Post Adder ---> Add
   end //initial	
	
   // always @ (posedge clk) begin
   //    next_signal = valid_inputs;
   // end

	// always @(posedge clk) begin
 //      if(valid_inputs) begin
 //         // clock_enable <= 1;
 //         count <= count + 1;
 //        if(count == 2) begin
 //            p_ready_pulse_generator <= ~ p_ready_pulse_generator;
	// 			count = 0;
 //        end // if(count == 2) 
 //      end // if(valid_inputs)
 //      // else begin
 //      //    // clock_enable <= 0;
 //      // end // else(valid_inputs)
	// end // always

   // always @(posedge clk) begin
   //    p_ready_pulse_generator <= ~ p_ready_pulse_generator;
   // end 

endmodule // module mac_module

module testbench();
   reg CLK;
   reg RESET;
   reg [17:0] DATA_A,DATA_B;
   wire [47:0] DATA_P;
   // wire [35:0] DATA_M;
   // wire [17:0] BCOUT;
   reg A_VALID,B_VALID;
	wire P_READY;

   // reg toggle;
   reg [47:0] p_out;

   mac_module m(
      .clk(CLK),
      .reset(RESET),
      .data_a(DATA_A),
      .data_b(DATA_B),
      .data_p(DATA_P),
      .a_valid(A_VALID),
      .b_valid(B_VALID),
      .p_ready(P_READY)
      );

   // pulse_generator #(
   //    .PULSE_WIDTH(32'd1)
   //    ) p5(
   //    .clk(CLK),
   //    .generate_pulse(toggle), // pulse generator
   //    .pulse(pulse_out) // generates a PULSE on p_ready
   //    );

   // initial begin
   //    toggle = 0;
   // end

   // always @(posedge CLK) begin

   initial begin
		p_out = 0;
      CLK = 0;
      DATA_A = 0;
      DATA_B = 0;
		A_VALID = 0;
		B_VALID = 0;
		RESET = 0;
   end

   always begin
      #5 CLK = ~ CLK;
   end

   initial begin
      #125 DATA_A = 20;
      DATA_B = 2;
      A_VALID = 1;
      B_VALID = 1;
      #10 A_VALID = 0;
      B_VALID = 0;

      #10 DATA_A = 2;
      DATA_B = 30;
      A_VALID = 1;
      B_VALID = 1;
      #10 A_VALID = 0;
      B_VALID = 0;
      
      #20 DATA_A = 30;
      DATA_B = 3;
      A_VALID = 1;
      B_VALID = 1;
      #10 A_VALID = 0;
      #10 B_VALID = 0;
      
      #30 DATA_A = 9;
      DATA_B = 10;
      A_VALID = 1;
      B_VALID = 1;
      #10 A_VALID = 0;
      B_VALID = 0;
		
		#40 DATA_A = 0;
      DATA_B = 0;
      A_VALID = 1;
      B_VALID = 1;
		#50 RESET = 1;
	end

   always @(posedge P_READY) begin
      p_out = DATA_P;
   end

endmodule // module testbench