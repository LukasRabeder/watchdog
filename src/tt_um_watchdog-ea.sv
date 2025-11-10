module tt_um_watchdog 
(
    input  logic clk,
    input  logic rst_n,
    input  logic ena,
    input  logic [7:0] ui_in,       // User Input (7 bits)
    input  logic [7:0] uio,       // User InOut (7 bits)
    output logic [7:0] uo_out      // User Output (8 bits)
);
    logic clk_i;
    logic rst_n_i;

    logic [7:0] ui_in_i;
    logic [7:0] uio_i;
    logic [7:0] uo_out_i;

    // Handshake signals
    logic core_busy_;
    logic res_valid;  // 1-cycle pulse: results ready
    logic ol_busy;
    logic start_ol;
    logic eig_core_start;

    // Data
    signed [31:0] alpha, beta;
    signed [31:0] invK, K;
    logic [2:0] regime;

    assign clk_i = clk;
    assign rst_n_i = rst_n;
    assign ui_in_i = {1'b0, ui_in};  // Pad ui_in to 8 bits
    assign uio_i = {1'b0, uio};    // Pad uio to 8 bits
    assign uo_out = uo_out_i;
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) 
  begin
    alpha <= 32'b0;
    beta  <= 32'b0;
    invK  <= 32'b0;
    K     <= 32'b0;
    regime <= 3'b000;
    uo_out <= 8'b0;
    core_busy <= 1'b0;
    res_valid <= 1'b0;
    ol_busy <= 1'b0;
    start_ol <= 1'b0;
    eig_core_start <= 1'b0;
  end 
  else 
  if (ena) 
  begin 
    // param_loader Instance
    param_loader u_pl 
    (
        .clk(clk_i),
        .rst_n(rst_n),
        .in_pins1(ui_in_i),
        .in_pins2(uio_i),
        .a0(alpha),
        .a1(beta),
        .core_busy(ol_busy && core_busy_),
        .start_calc(eig_core_start)
    );

    // eig_core Instance
    eig_core u_core (
        .clk(clk_i),
        .rst_n(rst_n_i),
        .data_rdy(1'b1),    //data_rdy immer true, durch datenvalidierung im Param Loader
        .a0(alpha),
        .a1(beta),
        .core_busy(core_busy_),
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
  end
  else
  begin
    uo_out <= 8'b0;
  end
end


endmodule
