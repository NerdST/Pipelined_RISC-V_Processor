// M-extension multiplier: combinational, single-cycle.
// op: 00=mul (low 32), 01=mulh (hi s*s), 10=mulhsu (hi s*u), 11=mulhu (hi u*u)
// Synthesis maps to DSP48 slices on Artix-7.
module multiplier(
  input  logic [31:0] a, b,
  input  logic [1:0]  op,
  output logic [31:0] result
);

  logic signed [63:0] ss;   // signed x signed
  logic        [63:0] uu;   // unsigned x unsigned
  logic signed [32:0] a33, b33;
  logic signed [65:0] su;   // signed x unsigned (33-bit trick)

  assign ss  = $signed(a) * $signed(b);
  assign uu  = {32'd0, a} * {32'd0, b};
  assign a33 = {a[31], a};   // sign-extend a to 33 bits
  assign b33 = {1'b0,  b};   // zero-extend b to 33 bits (always non-negative signed)
  assign su  = a33 * b33;

  always_comb
    case (op)
      2'b00: result = ss[31:0];    // mul:    lower 32 (same for all signedness)
      2'b01: result = ss[63:32];   // mulh:   upper 32, signed x signed
      2'b10: result = su[63:32];   // mulhsu: upper 32, signed x unsigned
      2'b11: result = uu[63:32];   // mulhu:  upper 32, unsigned x unsigned
    endcase

endmodule
