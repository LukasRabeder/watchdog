/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Clock generation: 10ns period (100MHz)
  reg clk = 0;
  always #5 clk = ~clk; // toggles every 5ns

  // Inputs
  reg rst_n = 0;
  reg ena = 0;
  reg [7:0] ui_in = 0;
  reg [7:0] uio_in = 0;

  // Outputs
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  // wire valid; // Uncomment if your module has a 'valid' output

  // Instantiate your module, replace with your exact module name and ports
  tt_um_watchdog uut (
    // Include power ports if needed, typically during gate-level simulations
`ifdef GL_TEST
    .VPWR(1'b1),
    .VGND(1'b0),
`endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
    // .valid (valid) // Uncomment if applicable
  );

  // Stimulus process
  initial begin
    // Reset sequence
    rst_n = 0;
    ena = 0;
    ui_in = 8'h00;
    uio_in = 8'h00;
    #20;  // hold reset for 20ns

    rst_n = 1; // release reset
    #10;

    // Enable the watchdog
    ena = 1;

    // Provide test inputs here
    ui_in = 8'hAA;    // example input pattern
    uio_in = 8'h55;   // example input pattern

    // Run some cycles
    repeat (50) @(posedge clk);

    // Example: change inputs mid-simulation
    ui_in = 8'hFF;
    uio_in = 8'h00;
    #20;

    // Disable en after some time
    ena = 0;

    // Finish simulation
    #20;
    $finish;
  end

endmodule
