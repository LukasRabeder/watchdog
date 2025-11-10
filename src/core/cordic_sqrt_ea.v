module cordic_sqrt #(
  parameter IN_WIDTH  = 32,
  parameter OUT_WIDTH = IN_WIDTH/2
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic signed [IN_WIDTH-1:0] x_in,
  output logic [OUT_WIDTH-1:0] y_out,
  output logic done,
  output logic is_neg
);

  // States
  typedef enum logic [2:0] {IDLE, RUN, FIN} state_t;
  logic [2:0] st;

  // Registers
  logic neg_flag;
  logic [IN_WIDTH-1:0] radicand;
  logic [IN_WIDTH-1:0] shreg;
  logic [OUT_WIDTH*2-1:0] remind;
  logic [OUT_WIDTH-1:0] root;
  integer iter;

  always_comb begin
    y_out = root;
    done  = (st == FIN) ? 1'b1 : 1'b0;
    is_neg = neg_flag;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st       <= IDLE;
      neg_flag <= 1'b0;
      radicand <= '0;
      shreg    <= '0;
      remind   <= '0;
      root     <= '0;
      iter     <= 0;
    end else begin
      case (st)
        IDLE: begin
          if (start) begin
            // Calculate absolute value and set negative flag
            if (x_in[IN_WIDTH-1] == 1'b1) begin
              neg_flag <= 1'b1;
              radicand <= '0; // we calculate 0 and flag it
            end else begin
              neg_flag <= 1'b0;
              radicand <= unsigned'(x_in);
            end

            shreg <= (x_in[IN_WIDTH-1] == 1'b0) ? unsigned'(x_in) : '0;

            remind <= '0;
            root   <= '0;
            iter   <= OUT_WIDTH;
            st     <= RUN;
          end
        end

        RUN: begin
          // Take the two most significant bits, then shift left
          logic [1:0] bring2 = shreg[IN_WIDTH-1:IN_WIDTH-2];
          shreg <= {shreg[IN_WIDTH-3:0], 2'b00};

          // rem = (rem << 2) | bring_down_two_bits
          logic [OUT_WIDTH*2-1:0] rem_next = {remind[OUT_WIDTH*2-3:0], bring2};

          // trial = (root << 1) | 1
          logic [OUT_WIDTH:0] trial = {root, 1'b0} + 1'b1;

          if (rem_next >= trial) begin
            // Subtract and append '1' to root
            remind <= rem_next - trial[OUT_WIDTH*2-1:0];
            root   <= {root[OUT_WIDTH-2:0], 1'b1};
          end else begin
            // No subtraction, append '0' to root
            remind <= rem_next;
            root   <= {root[OUT_WIDTH-2:0], 1'b0};
          end

          iter <= iter - 1;
          if (iter == 1) begin
            st <= FIN;
          end
        end

        FIN: begin
          // One clock cycle 'done', then return to IDLE
          st <= IDLE;
        end
      endcase
    end
  end

endmodule
