module watchdog 
(
    input  logic clk,
    input  logic rst_n,
    input  logic [6:0] ui_in,       // User Input (7 bits)
    input  logic [6:0] uio,       // User InOut (7 bits)
    output logic [7:0] uo_out      // User Output (8 bits)
);

    // Internal Signals
    logic clk_i;
    logic rst_n_i;
    logic [7:0] ui_in_i;
    logic [7:0] uio_i;
    logic [7:0] uo_out_i;

    // Handshake signals
    logic core_busy;
    logic res_valid;  // 1-cycle pulse: results ready
    logic ol_busy;
    logic start_ol;
    logic eig_core_start;

    // Data
    logic signed [31:0] alpha, beta;
    logic signed [31:0] invK, K;
    logic [2:0] regime;

    assign clk_i = clk;
    assign rst_n_i = rst_n;
    assign ui_in_i = {1'b0, ui_in};  // Pad ui_in to 8 bits
    assign uio_i = {1'b0, uio};    // Pad uio to 8 bits
    assign uo_out = uo_out_i;

    // param_loader Instance
    param_loader u_pl (
        .clk(clk_i),
        .rst_n(rst_n),
        .in_pins1(ui_in_i),
        .in_pins2(uio_i),
        .a0(alpha),
        .a1(beta),
        .core_busy(core_busy),
        .start_calc(eig_core_start)
    );

    // eig_core Instance
    eig_core u_core (
        .clk(clk_i),
        .rst_n(rst_n_i),
        .data_rdy(1'b1),    //data_rdy immer true, durch datenvalidierung im Param Loader
        .a0(alpha),
        .a1(beta),
        .core_busy(core_busy),
        .kappa(K),
        .inv_kappa(invK),
        .regime(regime)
    );

    // output_loader Instance
    output_loader u_ol (
        .clk(clk_i),
        .rst_n(rst_n_i),
        .start(start_ol),
        .mode(regime),
        .wordA(K),
        .wordB(invK),
        .busy(ol_busy),
        .out_byte(uo_out_i)
    );

endmodule
