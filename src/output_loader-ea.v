include "watchdog_pkg.v"
module output_loader #(
    parameter W = 32
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [2:0] mode,
    input  logic [W-1:0] wordA,
    input  logic [W-1:0] wordB,
    output logic busy,
    output logic [7:0] out_byte
);

    // Internal Signals
    typedef enum logic [1:0] {IDLE, SEND_A, SEND_B} state_t;
    state_t state;

    logic [W-1:0] shift_reg;
    integer nibble_idx; // integer range 0 to 7
    logic [2:0] cur_mode;
    logic data_rdy;

    assign busy = (state != IDLE) ? 1'b1 : 1'b0;

    // Function to select a nibble
    function logic [3:0] sel_nibble32(logic [W-1:0] data, integer index);
        begin
            case (index)
                0: sel_nibble32 = data[3:0];
                1: sel_nibble32 = data[7:4];
                2: sel_nibble32 = data[11:8];
                3: sel_nibble32 = data[15:12];
                4: sel_nibble32 = data[19:16];
                5: sel_nibble32 = data[23:20];
                6: sel_nibble32 = data[27:24];
                7: sel_nibble32 = data[31:28];
                default: sel_nibble32 = 4'b0; // Default case
            endcase
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            nibble_idx <= 0;
            cur_mode <= 3'b000;
            data_rdy <= 1'b0;
            out_byte <= 8'b0;
            shift_reg <= {W{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    data_rdy <= 1'b0;
                    if (start) begin
                        cur_mode <= mode;
                        shift_reg <= wordA;
                        nibble_idx <= 7;
                        data_rdy <= 1'b1;
                        state <= SEND_A;
                    end
                end
                SEND_A: begin
                    out_byte <= {cur_mode, 1'b1, sel_nibble32(shift_reg, nibble_idx)}; // [7:5]mode [4]rdy [3:0]nibble
                    if (nibble_idx == 0) begin
                        shift_reg <= wordB;
                        nibble_idx <= 7;
                        state <= SEND_B;
                    end else begin
                        nibble_idx <= nibble_idx - 1;
                    end
                end
                SEND_B: begin
                    out_byte <= {cur_mode, 1'b1, sel_nibble32(shift_reg, nibble_idx)};
                    if (nibble_idx == 0) begin
                        data_rdy <= 1'b0;
                        out_byte <= 8'b0;
                        state <= IDLE;
                    end else begin
                        nibble_idx <= nibble_idx - 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
