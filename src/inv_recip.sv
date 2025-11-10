
module inv_recip #(
  parameter W = 32,
  parameter F = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start_calc,
  output logic done,
  input  logic signed [W-1:0] x_in,
  output logic [W-1:0] x_inv,
  output logic invalid
);

  // LUT for initial value (QF)
  logic [W-1:0] inv_lut [0:15] = {
    32'd65536,  // 1.0000 Q16
    32'd61440,  // 0.9375
    32'd57344,  // 0.8750
    32'd53248,  // 0.8125
    32'd49152,  // 0.7500
    32'd45056,  // 0.6875
    32'd40960,  // 0.6250
    32'd36864,  // 0.5625
    32'd32768,  // 0.5000
    32'd28672,  // 0.4375
    32'd24576,  // 0.3750
    32'd20480,  // 0.3125
    32'd16384,  // 0.2500
    32'd12288,  // 0.1875
    32'd8192,   // 0.1250
    32'd4096    // 0.0625
  };

  // State type
  typedef enum logic [3:0] {S_IDLE, S_CHECK, S_NORM, S_LUT, S_IT0, S_IT1, S_IT2, S_IT3, S_DEN, S_DONE} st_t;
  logic [3:0] st = S_IDLE;

  logic [W-1:0] x_abs;
  logic [W-1:0] x_norm;  // QF, in [0.5,1)
  integer signed e = 0;

  logic [W-1:0] y;       // QF, iterative reciprocal
  integer idx = 0;
  integer s = 0;

  // Width for QF*QF
  localparam M = 2*W;
  logic [M-1:0] xy;
  logic [M-1:0] yc;
  logic [W-1:0] tmpQF;
  // Function to find MSB position
//function automatic integer msb_pos(logic [W-1:0] u);
//  integer result = 0;
//  begin
//    for (int i = 0; i < W; i++) begin
//      if (u[W-1 - i] == 1'b1) begin
//        result = W - 1 - i;
//        msb_pos = result; // assign the return value
//        return; // exit early
//      end
//    end
    // no bits set, default result
//    msb_pos = result;
//  end
//endfunction

  logic [$clog2(W)-1:0] msb_pos;
  logic found = 0;
  //logic [W-1:0] tmpQF;
  logic [W-1:0] TWO_QF = 2**(F+1); // 2.0 in QF

  always_comb 
  begin
    found = 0;
    invalid = (st == S_DONE && (x_in <= 0)) ? 1'b1 : 1'b0;
    done    = (st == S_DONE) ? 1'b1 : 1'b0;
    x_inv   = y;
    msb_pos = 0; // default value
    for (int i = W-1; i >= 0; i--) 
    begin
    if (x_abs[i] && !found) 
    begin
      msb_pos = i;
      found = 1; // exit loop early when first '1' is found from MSB
    end
  end
  // If x_abs is zero, msb_pos will be 0 (or adjust as needed)
  end

  always_ff @(posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
    begin
      st <= S_IDLE;
      x_abs <= '0;
      x_norm<= '0;
      e     <= 0;
      y     <= '0;
      idx   <= 0;
    end 
    else 
    begin
      case (st)
        S_IDLE: 
        begin
          if (start_calc == 1'b1) 
          begin
            st    <= S_CHECK;
            //done <= 1'b0;
          end
        end

        S_CHECK: 
        begin
          if (x_in <= 0) 
          begin
            y  <= '0;
            st <= S_DONE;
          end 
          else 
          begin
            x_abs <= unsigned'(x_in); // only positive domain
            st    <= S_NORM;
          end
        end

        S_NORM: 
        begin
          if (x_abs == 0) 
          begin
            y  <= '0;
            st <= S_DONE;
          end 
          else 
          begin
            s = (F-1) - msb_pos;              // Shift, to bring MSB to Bit F-1
            if (s >= 0) 
            begin
              x_norm <= x_abs << s;
            end 
            else 
            begin
              x_norm <= x_abs >> -s;
            end
            e <= -s;                     // x = x_norm * 2^e
            st <= S_LUT;
          end
        end

        S_LUT: 
        begin
          idx <= x_norm[W-1:W-4];        // upper Nibble
          y   <= inv_lut[x_norm[W-1:W-4]];
          st  <= S_IT0;
        end

        // Iteration: y = y * (2 - x_norm*y)
        // All sizes are QF
        S_IT0, S_IT1, S_IT2, S_IT3: 
        begin
          xy <= x_norm * y;           // QF*QF
          // (x*y)>>F  -> again QF
          tmpQF <= xy >> F;
          // corr = 2 - x*y
          yc <= y * (TWO_QF - tmpQF);   // QF*QF
          y  <= yc >> F; // back to QF
          case (st)
            S_IT0: st <= S_IT1;
            S_IT1: st <= S_IT2;
            S_IT2: st <= S_IT3;
            default: st <= S_DEN;
          endcase
        end

        S_DEN: begin
          // 1/x = (1/x_norm) * 2^{-e}
          if (e > 0) begin
            y <= y >> e;   // 2^{-e} with e>0 => >> e
          end else if (e < 0) begin
            y <= y << -e;   // 2^{-e} with e<0 => << (-e)
          end
          st <= S_DONE;
          //done <= 1'b0;
        end

        S_DONE: 
        begin
          st <= S_IDLE;
        end
        default: st <= S_IDLE;
      endcase
    end
  end

endmodule
