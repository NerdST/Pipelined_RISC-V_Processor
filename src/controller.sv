module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       funct7b0,   // high for M-extension (funct7 = 0000001)
                  output logic       RegWrite,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       Jump,
                  output logic       Branch,
                  output logic [3:0] ALUControl,
                  output logic       ALUSrc,
                  output logic [2:0] ImmSrc,
                  output logic [1:0] ExecUnit,   // 00=ALU, 01=multiplier, 10=divider
                  output logic       IsJalr,     // 1 for jalr: PC target = ALUResult & ~1
                  output logic       ALUSrcA);   // 1 for auipc: SrcA = PC instead of register

  // Main Decoder Truth Table
  // Instruction  Opcode    RegWrite ImmSrc ALUSrc ALUSrcA MemWrite ResultSrc Branch ALUOp Jump IsJalr
  // lw/lb/lh..   0000011   1        000    1      0       0        01        0      00    0    0
  // sw/sh/sb     0100011   0        001    1      0       1        xx        0      00    0    0
  // R-type/M     0110011   1        xxx    0      0       0        00        0      10    0    0
  // branches     1100011   0        010    0      0       0        xx        1      01    0    0
  // I-type ALU   0010011   1        000    1      0       0        00        0      10    0    0
  // jal          1101111   1        011    x      0       0        10        0      xx    1    0
  // jalr         1100111   1        000    1      0       0        10        0      00    1    1
  // lui          0110111   1        100    x      0       0        11        0      xx    0    0
  // auipc        0010111   1        100    1      1       0        00        0      00    0    0

  logic [1:0] ALUOp_internal;
  logic RtypeSub;
  logic IsMExt;

  // M-extension: same opcode as R-type but funct7 = 0000001
  assign IsMExt = (op == 7'b0110011) & funct7b0;

  // Main Decoder — default everything to 0 first to avoid latches
  always_comb begin
    RegWrite       = 1'b0;
    ImmSrc         = 3'b000;
    ALUSrc         = 1'b0;
    MemWrite       = 1'b0;
    ResultSrc      = 2'b00;
    Branch         = 1'b0;
    ALUOp_internal = 2'b00;
    Jump           = 1'b0;
    IsJalr         = 1'b0;
    ALUSrcA        = 1'b0;

    case(op)
      7'b0000011: begin // lw / lb / lh / lbu / lhu (funct3 selects width)
        RegWrite  = 1'b1; ImmSrc = 3'b000; ALUSrc = 1'b1;
        ResultSrc = 2'b01;
      end
      7'b0100011: begin // sw / sh / sb
        ImmSrc = 3'b001; ALUSrc = 1'b1; MemWrite = 1'b1;
      end
      7'b0110011: begin // R-type (base) and M-extension
        RegWrite = 1'b1; ALUOp_internal = 2'b10;
      end
      7'b1100011: begin // beq / bne / blt / bge / bltu / bgeu
        ImmSrc = 3'b010; Branch = 1'b1; ALUOp_internal = 2'b01;
      end
      7'b0010011: begin // I-type ALU (addi / slti / sltiu / xori / ori / andi / slli / srli / srai)
        RegWrite = 1'b1; ImmSrc = 3'b000; ALUSrc = 1'b1;
        ALUOp_internal = 2'b10;
      end
      7'b1101111: begin // jal
        RegWrite = 1'b1; ImmSrc = 3'b011; ResultSrc = 2'b10; Jump = 1'b1;
      end
      7'b1100111: begin // jalr — PC target = (rs1 + imm) & ~1
        RegWrite = 1'b1; ImmSrc = 3'b000; ALUSrc = 1'b1;
        ResultSrc = 2'b10; Jump = 1'b1; IsJalr = 1'b1;
      end
      7'b0110111: begin // lui
        RegWrite = 1'b1; ImmSrc = 3'b100; ResultSrc = 2'b11;
      end
      7'b0010111: begin // auipc — rd = PC + upper_imm
        RegWrite = 1'b1; ImmSrc = 3'b100; ALUSrc = 1'b1; ALUSrcA = 1'b1;
      end
      default: ; // all signals already 0
    endcase
  end

  // ExecUnit: select execution unit for M-extension
  // funct3[2]=0: mul/mulh/mulhsu/mulhu -> multiplier
  // funct3[2]=1: div/divu/rem/remu     -> divider
  always_comb begin
    if (IsMExt)
      ExecUnit = funct3[2] ? 2'b10 : 2'b01;
    else
      ExecUnit = 2'b00;
  end

  // ALU Decoder
  // Guard funct7b0 so M-ext mul (funct3=000) is not misread as subtract
  assign RtypeSub = funct7b5 & op[5] & ~funct7b0;

  always_comb
    if (IsMExt)
      ALUControl = 4'b0000;  // ALU unused for M-extension; result comes from mul/div unit
    else
      case(ALUOp_internal)
        2'b00: ALUControl = 4'b0000; // add (lw/sw/lui/jal/jalr/auipc)
        2'b01: ALUControl = 4'b0001; // subtract (branches — actual compare done in datapath)
        2'b10: case(funct3)
                 3'b000: ALUControl = RtypeSub ? 4'b0001 : 4'b0000; // sub / add/addi
                 3'b001: ALUControl = 4'b0110; // sll / slli
                 3'b010: ALUControl = 4'b0101; // slt / slti
                 3'b011: ALUControl = 4'b1001; // sltu / sltiu
                 3'b100: ALUControl = 4'b0100; // xor / xori
                 3'b101: ALUControl = funct7b5 ? 4'b1000 : 4'b0111; // sra/srai vs srl/srli
                 3'b110: ALUControl = 4'b0011; // or  / ori
                 3'b111: ALUControl = 4'b0010; // and / andi
                 default: ALUControl = 4'b0000;
               endcase
        default: ALUControl = 4'b0000;
      endcase
endmodule
