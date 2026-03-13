module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  output logic       RegWrite,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       Jump,
                  output logic       Branch,
                  output logic [2:0] ALUControl,
                  output logic       ALUSrc,
                  output logic [1:0] ImmSrc);


  // Main Decoder Truth Table
  // Instruction  Opcode    RegWrite ImmSrc ALUSrcA ALUSrcB MemWrite ResultSrc Branch ALUOp Jump
  // lw           0000011   1        00     0       1       0        01        0      00    0
  // sw           0100011   0        01     0       1       1        xx        0      00    0
  // R-type       0110011   1        xx     0       0       0        00        0      10    0
  // beq          1100011   0        10     0       0       0        xx        1      01    0
  // I-type ALU   0010011   1        00     0       1       0        00        0      10    0
  // jal          1101111   1        11     x       x       0        10        0      xx    1
  // lui          0110111   1        11     x       x       0        11        0      xx    0
  
  logic [1:0] ALUOp_internal;
  logic RtypeSub;
  
  // Main Decoder
  always_comb
    case(op)
      7'b0000011: begin // lw
        RegWrite = 1'b1;
        ImmSrc = 2'b00;
        ALUSrc = 1'b1;
        MemWrite = 1'b0;
        ResultSrc = 2'b01;
        Branch = 1'b0;
        ALUOp_internal = 2'b00;
        Jump = 1'b0;
      end
      7'b0100011: begin // sw
        RegWrite = 1'b0;
        ImmSrc = 2'b01;
        ALUSrc = 1'b1;
        MemWrite = 1'b1;
        ResultSrc = 2'bxx;
        Branch = 1'b0;
        ALUOp_internal = 2'b00;
        Jump = 1'b0;
      end
      7'b0110011: begin // R-type
        RegWrite = 1'b1;
        ImmSrc = 2'bxx;
        ALUSrc = 1'b0;
        MemWrite = 1'b0;
        ResultSrc = 2'b00;
        Branch = 1'b0;
        ALUOp_internal = 2'b10;
        Jump = 1'b0;
      end
      7'b1100011: begin // beq
        RegWrite = 1'b0;
        ImmSrc = 2'b10;
        ALUSrc = 1'b0;
        MemWrite = 1'b0;
        ResultSrc = 2'bxx;
        Branch = 1'b1;
        ALUOp_internal = 2'b01;
        Jump = 1'b0;
      end
      7'b0010011: begin // I-type ALU
        RegWrite = 1'b1;
        ImmSrc = 2'b00;
        ALUSrc = 1'b1;
        MemWrite = 1'b0;
        ResultSrc = 2'b00;
        Branch = 1'b0;
        ALUOp_internal = 2'b10;
        Jump = 1'b0;
      end
      7'b1101111: begin // jal
        RegWrite = 1'b1;
        ImmSrc = 2'b11;
        ALUSrc = 1'bx;
        MemWrite = 1'b0;
        ResultSrc = 2'b10;
        Branch = 1'b0;
        ALUOp_internal = 2'bxx;
        Jump = 1'b1;
      end
      7'b0110111: begin // lui
        RegWrite = 1'b1;
        ImmSrc = 2'b11;
        ALUSrc = 1'bx;
        MemWrite = 1'b0;
        ResultSrc = 2'b11;
        Branch = 1'b0;
        ALUOp_internal = 2'bxx;
        Jump = 1'b0;
      end
      default: begin
        RegWrite = 1'b0;
        ImmSrc = 2'b00;
        ALUSrc = 1'b0;
        MemWrite = 1'b0;
        ResultSrc = 2'b00;
        Branch = 1'b0;
        ALUOp_internal = 2'b00;
        Jump = 1'b0;
      end
    endcase
  
  // ALU Decoder
  // ALU Decoder Truth Table
  // ALUOp[1:0] | funct3[2:0] | {op[5], funct7[5]} | ALUControl[2:0] | Operation
  // 00         | x           | x                   | 000             | Add
  // 01         | x           | x                   | 001             | Subtract
  // 10         | 000         | 00, 01, 10         | 000             | Add
  // 10         | 000         | 11                 | 001             | Subtract
  // 10         | 010         | x                  | 101             | SLT
  // 10         | 110         | x                  | 011             | OR
  // 10         | 111         | x                  | 010             | AND
  
  assign RtypeSub = funct7b5 & op[5]; // TRUE for R-type subtract instruction
  
  always_comb
    case(ALUOp_internal)
      2'b00: ALUControl = 3'b000; // addition
      2'b01: ALUControl = 3'b001; // subtraction
      2'b10: case(funct3) // R-type or I-type ALU
               3'b000: if (RtypeSub)
                 ALUControl = 3'b001; // subtract (funct7b5=1)
               else
                 ALUControl = 3'b000; // add (funct7b5=0)
               3'b010: ALUControl = 3'b101; // slt
               3'b110: ALUControl = 3'b011; // or
               3'b111: ALUControl = 3'b010; // and
               default: ALUControl = 3'bxxx;
             endcase
      default: ALUControl = 3'bxxx;
    endcase
endmodule