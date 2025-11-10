
module eig_core (
    input  logic ena,
    input  logic clk,
    input  logic rst_n,
    input  logic data_rdy,
    input  logic signed [31:0] a0,
    input  logic signed [31:0] a1,
    output logic core_busy,
    output logic signed [31:0] kappa,
    output logic signed [31:0] inv_kappa,
    output logic [2:0] regime
);

    // Internal Signals
    logic signed [31:0] alpha, beta;
    logic start_calc;
    logic disc_neg;
    //logic data_rdy_;

    // Handshake signals for cordic_sqrt
    logic sqrt_start;
    logic sqrt_done;

    // Handshake signals for inv_recip
    logic inv_start;
    logic inv_done;
    //logic invalid;

    logic calc_done_q;
    logic [2:0] regime_q;
    logic signed [63:0] alpha4, beta_sq, disc_q;
    logic signed [31:0] kappa_q, inv_kappa_q, sqrt_disc_half_q;

    typedef enum logic [3:0] {IDLE, PREP_DISC, CALC_DISC, WAIT_SQRT, CALC_INV, DONE} state_type;
    state_type state;

    // cordic_sqrt Instance
    cordic_sqrt #(
        .IN_WIDTH(64),
        .OUT_WIDTH(32)
    ) sqrt_instance (
        .clk(clk),
        .rst_n(rst_n),
        .start(sqrt_start),
        .x_in(disc_q),
        .y_out(sqrt_disc_half_q),
        .done(sqrt_done),
        .is_neg(disc_neg)
    );

    //inv_recip Instance
    inv_recip #(
        .W(32),
        .F(16)
    ) inv_instance (
        .clk(clk),
        .rst_n(rst_n),
        .start_calc(inv_start),
        .x_in(kappa_q),
        .x_inv(inv_kappa_q),
        .done(inv_done)
        //.invalid(invalid)
    );

    assign core_busy = ~calc_done_q;
    assign regime = regime_q;
    assign kappa = kappa_q;
    assign inv_kappa = inv_kappa_q;
    //assign data_rdy = data_rdy_;

    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            state <= IDLE;
            calc_done_q <= 1'b0;
            start_calc <= 1'b0;
            regime_q <= 3'b000;
            //alpha_q <= 32'b0;
            //beta_q <= 32'b0;
            //omega_q <= 32'b0;
            kappa_q <= 32'b0;
            //inv_kappa_q <= 32'b0;
            //neg_beta_h_q <= 32'b0;
            //sqrt_disc_half_q <= 32'b0;
            disc_neg <= 1'b0;

            // Initialize handshake signals
            sqrt_start <= 1'b0;
            //sqrt_done <= 1'b0;

            inv_start <= 1'b0;
            //inv_done <= 1'b0;

            //data_rdy_ <= 1'b0;

        end else if(ena) begin
            start_calc <= data_rdy;
            case (state)
                IDLE: begin
                    if (data_rdy) begin
                        alpha <= a0;
                        beta <= a1;
                        state <= PREP_DISC;
                    end
                end
                PREP_DISC: begin
                    //data_rdy_ <= 1'b0;
                    alpha4 <= alpha << 2; // alpha * 4
                    beta_sq <= $signed($unsigned(beta) * $unsigned(beta));
                    if (alpha4 < beta_sq) begin
                        regime_q <= 3'b100; // overdamped
                        disc_q <= alpha4 - beta_sq;
                    end else if (alpha4 == beta_sq) begin
                        regime_q <= 3'b010; // critical
                        disc_q <= 64'b0;
                    end else begin
                        regime_q <= 3'b001; // underdamped
                        disc_q <= beta_sq - alpha4;
                    end
                    sqrt_start <= 1'b1; // Start sqrt calculation
                    state <= CALC_DISC;
                end
                CALC_DISC: begin
                    if (sqrt_done) begin
                        sqrt_start <= 1'b0; // Deassert sqrt_start
                        //sqrt_disc_half_q <= sqrt_disc_half_q >> 1; // sqrt(disc)/2
                        //neg_beta_h_q <= -beta >>> 1; // -beta/2

                        // Calculate kappa based on regime
                        if (regime_q == 3'b010) 
                        begin
                            kappa_q <= 32'b0;
                        end 
                        else 
                        begin
                            kappa_q <= sqrt_disc_half_q; // underdamped
                        end

                        inv_start <= 1'b1; //Start inverse Calculation
                        state <= CALC_INV;
                    end
                end
                CALC_INV: 
                begin
                    if (inv_done) 
                    begin
                      inv_start <= 1'b0;
                      state <= DONE;
                    end
                end
                DONE: 
                begin
                    calc_done_q <= 1'b1;
                    //data_rdy_ = 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
        else
        begin
            state <= IDLE;
            //regime <= 3'b0;
            //kappa <= 32'b0;
            //inv_kappa <= 32'b0;
        end
    end
endmodule
