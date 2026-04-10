module alu(input  logic [31:0] a, b,
           input  logic [3:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);

  logic [31:0] condinvb, sum;
  logic        v;              // overflow
  logic        isAddSub;       // true when is add or subtract operation

  assign condinvb = alucontrol[0] ? ~b : b;
  assign sum = a + condinvb + alucontrol[0];
  // isAddSub: true only for add (4'b0000) and sub (4'b0001); guard with ~[3] so
  // sra (4'b1000) does not match despite sharing lower-bit pattern with add.
  assign isAddSub = ~alucontrol[3] & (~alucontrol[2] & ~alucontrol[1] |
                                       ~alucontrol[1] & alucontrol[0]);

  always_comb
    case (alucontrol)
      4'b0000:  result = sum;                               // add
      4'b0001:  result = sum;                               // subtract
      4'b0010:  result = a & b;                             // and
      4'b0011:  result = a | b;                             // or
      4'b0100:  result = a ^ b;                             // xor
      4'b0101:  result = {31'b0, sum[31] ^ v};              // slt  (signed)
      4'b0110:  result = a << b[4:0];                       // sll
      4'b0111:  result = a >> b[4:0];                       // srl
      4'b1000:  result = $signed(a) >>> b[4:0];             // sra
      4'b1001:  result = {31'b0, (a < b)};                  // sltu (unsigned)
      default:  result = 32'bx;
    endcase

  assign zero = (result == 32'b0);
  assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
endmodule
