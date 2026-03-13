module riscvprocessor(input  logic        clk, reset,
             output logic [31:0] PCF,
             input  logic [31:0] InstrF,
             output logic        MemWrite,
             output logic [31:0] ALUResultM,
             output logic [31:0] WriteData,
             input  logic [31:0] ReadData);

  logic        PCSrcE, RegWriteW;
  
  // Control signals from controller (Decode stage)
  logic       RegWriteD, MemWriteD, BranchD, JumpD;
  logic [1:0] ImmSrcD, ResultSrcD;
  logic       ALUSrcD;
  logic [2:0] ALUControlD;
  
  // Signals passed from Decode to Execute
  logic       RegWriteE, MemWriteE, BranchE, JumpE;
  logic [1:0] ImmSrcE, ResultSrcE;
  logic       ALUSrcE;
  logic [2:0] ALUControlE;
  
  // instantiate datapath (contains controller instantiation internally)
  datapath dp(clk, reset,
              InstrF,
              PCF, ALUResultM, WriteData, ReadData,
              MemWrite);
endmodule