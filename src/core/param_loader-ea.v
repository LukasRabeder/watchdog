module param_loader (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] in_pins1,
    input  logic [7:0] in_pins2,
    output logic signed [31:0] a0,
    output logic signed [31:0] a1,
    output logic start_calc,
    input  logic core_busy
);

    // Internal Signals
    typedef enum logic [1:0] {S_IDLE, S_GOT_DATA, S_CORE_BUSY} state_type;
    state_type state;

    logic signed [31:0] a0_reg, a1_reg;
    logic start_q;
    logic ready_q;

    assign a0 = a0_reg;
    assign a1 = a1_reg;
    assign start_calc = ready_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            a0_reg <= 32'b0;
            a1_reg <= 32'b0;
            start_q <= 1'b0;
            ready_q <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    start_q <= ~core_busy;  // Invert core_busy

                    if (start_q) begin
                        a0_reg <= $signed({1'b0, in_pins1});  // Sign-extend in_pins1
                        a1_reg <= $signed({1'b0, in_pins2});  // Sign-extend in_pins2
                        state <= S_GOT_DATA;
                    end
                end
                S_GOT_DATA: begin
                    ready_q <= 1'b1;
                    state <= S_CORE_BUSY;
                end
                S_CORE_BUSY: begin
                    start_q <= ~core_busy;

                    if (start_q) begin
                        state <= S_IDLE;
                        ready_q <= 1'b0;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
