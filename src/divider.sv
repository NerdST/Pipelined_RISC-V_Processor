// M-extension divider: iterative restoring division, ~34-cycle latency.
// op: 00=div, 01=divu, 10=rem, 11=remu
// start pulses for 1 cycle when a div/rem first enters Execute.
// busy goes high on start and low when done.
// done pulses for exactly 1 cycle when result is valid.
module divider(
  input  logic        clk, reset,
  input  logic [31:0] a, b,
  input  logic [1:0]  op,
  input  logic        start,
  output logic [31:0] result,
  output logic        done,
  output logic        busy
);

  localparam IDLE    = 2'd0;
  localparam RUNNING = 2'd1;
  localparam FINISH  = 2'd2;

  logic [1:0]  state;
  logic [5:0]  count;
  logic [63:0] working;     // [63:32] = partial remainder, [31:0] = developing quotient
  logic [31:0] divisor_reg;
  logic        neg_quot_reg, neg_rem_reg;
  logic [1:0]  op_reg;

  // Combinational absolute values of inputs (for signed ops, op[0]=0 means signed)
  logic [31:0] a_abs, b_abs;
  assign a_abs = (~op[0] & a[31]) ? (~a + 1'b1) : a;
  assign b_abs = (~op[0] & b[31]) ? (~b + 1'b1) : b;

  // Restoring division trial subtraction:
  // Each step shifts working left by 1, then tries subtracting divisor from upper 32 bits.
  // working[62:31] = upper 32 bits of (working << 1)
  logic [32:0] partial;
  assign partial = {1'b0, working[62:31]} - {1'b0, divisor_reg};

  // Sign-corrected final outputs (combinational, read in FINISH state)
  logic [31:0] quot_corrected, rem_corrected;
  assign quot_corrected = neg_quot_reg ? (~working[31:0]  + 1'b1) : working[31:0];
  assign rem_corrected  = neg_rem_reg  ? (~working[63:32] + 1'b1) : working[63:32];

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state        <= IDLE;
      done         <= 1'b0;
      busy         <= 1'b0;
      count        <= 6'd0;
      result       <= 32'd0;
      working      <= 64'd0;
      divisor_reg  <= 32'd0;
      neg_quot_reg <= 1'b0;
      neg_rem_reg  <= 1'b0;
      op_reg       <= 2'd0;
    end else begin
      done <= 1'b0;  // done pulses for exactly one cycle

      case (state)
        IDLE: begin
          if (start) begin
            op_reg <= op;
            if (b == 32'd0) begin
              // Divide by zero: quotient = 0xFFFFFFFF, remainder = dividend (RISC-V spec)
              result <= op[1] ? a : 32'hFFFFFFFF;
              done   <= 1'b1;
            end else if (!op[0] && a == 32'h80000000 && b == 32'hFFFFFFFF) begin
              // Signed overflow: INT_MIN / -1 = INT_MIN, remainder = 0 (RISC-V spec)
              result <= op[1] ? 32'd0 : 32'h80000000;
              done   <= 1'b1;
            end else begin
              working      <= {32'd0, a_abs};
              divisor_reg  <= b_abs;
              neg_quot_reg <= (~op[0]) & (a[31] ^ b[31]);
              neg_rem_reg  <= (~op[0]) & a[31];
              count        <= 6'd0;
              busy         <= 1'b1;
              state        <= RUNNING;
            end
          end
        end

        RUNNING: begin
          // Restoring division step: shift left, subtract, restore if negative
          if (!partial[32])
            working <= {partial[31:0], working[30:0], 1'b1};  // quotient bit = 1
          else
            working <= {working[62:0], 1'b0};                 // quotient bit = 0

          if (count == 6'd31)
            state <= FINISH;
          else
            count <= count + 6'd1;
        end

        FINISH: begin
          result <= op_reg[1] ? rem_corrected : quot_corrected;
          done   <= 1'b1;
          busy   <= 1'b0;
          state  <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
