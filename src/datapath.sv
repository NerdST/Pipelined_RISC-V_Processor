module datapath(input  logic        clk, reset,
                input  logic [31:0] InstrF,
                output logic [31:0] PCF,
                output logic [31:0] ALUResultM,
                output logic [31:0] WriteDataM,
                input  logic [31:0] ReadDataM,
                output logic        MemWrite,
                output logic        MemReadM,
                output logic [2:0]  MemFunct3M);  // funct3 in M stage for byte/half access

  // Fetch stage signals
  logic [31:0] PCPlus4F, PCFa, PCTargetE;
  logic        StallF, StallD, StallE, FlushD, FlushE;
  logic        PCSrcE;

  // Decode stage signals
  logic [31:0] InstrD, PCD, PCPlus4D;
  logic [31:0] RD1D, RD2D, ImmExtD;
  logic [31:0] RD1D_raw, RD2D_raw;
  logic [4:0]  Rs1D, Rs2D, RdD;
  logic        RegWriteD, MemWriteD, JumpD, BranchD;
  logic [1:0]  ResultSrcD;
  logic [2:0]  ImmSrcD;
  logic [3:0]  ALUControlD;
  logic [2:0]  BranchTypeD;
  logic        ALUSrcD;
  logic [1:0]  ALUOpD;
  logic [1:0]  ExecUnitD;
  logic        IsJalrD, ALUSrcAD;
  logic [2:0]  MemFunct3D;

  // Control signals from controller
  logic [6:0]  OpD;
  logic [2:0]  Funct3D;
  logic        Funct7b5D;
  logic        Funct7b0D;

  // Execute stage signals
  logic [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  logic [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE;
  logic [31:0] SrcAE_Fwd, SrcBE_Fwd;
  logic [4:0]  Rs1E, Rs2E, RdE;
  logic        RegWriteE, MemWriteE, JumpE, BranchE, ZeroE;
  logic [1:0]  ResultSrcE, ForwardAE, ForwardBE;
  logic [3:0]  ALUControlE;
  logic [2:0]  BranchTypeE;
  logic        ALUSrcE;
  logic [31:0] SL12E;
  logic        branchEqE, branchLtSignedE, branchLtUnsignedE, branchTakenE;
  logic [1:0]  ExecUnitE;
  logic [1:0]  MulDivOpE;
  logic [31:0] MulResultE, DivResultE, ExecResultE;
  logic        divDone, divBusy, divStart;
  logic        IsJalrE, ALUSrcAE;
  logic [2:0]  MemFunct3E;
  logic [31:0] PCBranchE;  // PC + ImmExt (branch/jal target)

  // Memory stage signals
  logic [31:0] PCPlus4M, SL12M;
  logic [31:0] ResultMForward;
  logic [4:0]  RdM;
  logic        RegWriteM;
  logic [1:0]  ResultSrcM;
  logic        MemAccessM;

  // Writeback stage signals
  logic [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW, SL12W;
  logic [4:0]  RdW;
  logic        RegWriteW;
  logic [1:0]  ResultSrcW;

  // Hazard detection signals
  logic [1:0]  ForwardAE_sig, ForwardBE_sig;

  // ========== FETCH STAGE ==========
  mux2 #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCFa);
  flopenr #(32) pcreg(clk, reset, ~StallF, PCFa, PCF);
  adder pcadd4(PCF, 32'd4, PCPlus4F);

  // ========== FETCH/DECODE PIPELINE REGISTER ==========
  flopenrc #(32) instrdreg(clk, reset, FlushD, ~StallD, InstrF, InstrD);
  flopenrc #(32) pcdreg(clk, reset, FlushD, ~StallD, PCF, PCD);
  flopenrc #(32) pcplus4dreg(clk, reset, FlushD, ~StallD, PCPlus4F, PCPlus4D);

  // ========== DECODE STAGE ==========
  assign Rs1D      = InstrD[19:15];
  assign Rs2D      = InstrD[24:20];
  assign RdD       = InstrD[11:7];
  assign OpD       = InstrD[6:0];
  assign Funct3D   = InstrD[14:12];
  assign Funct7b5D = InstrD[30];
  assign Funct7b0D = InstrD[25];   // bit 0 of funct7; high for M-extension
  assign BranchTypeD = Funct3D;
  assign MemFunct3D  = Funct3D;    // pipelined to M stage for byte/half mem access

  controller ctrl(OpD, Funct3D, Funct7b5D, Funct7b0D,
                  RegWriteD, ResultSrcD, MemWriteD, JumpD,
                  BranchD, ALUControlD, ALUSrcD, ImmSrcD, ExecUnitD,
                  IsJalrD, ALUSrcAD);

  regfile rf(clk, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D_raw, RD2D_raw);

  // Decode-stage bypass for same-cycle W->D RAW hazards.
  assign RD1D = (RegWriteW && (RdW != 5'b0) && (RdW == Rs1D)) ? ResultW : RD1D_raw;
  assign RD2D = (RegWriteW && (RdW != 5'b0) && (RdW == Rs2D)) ? ResultW : RD2D_raw;

  extend ext(InstrD[31:7], ImmSrcD, ImmExtD);

  logic [31:0] SL12D;
  assign SL12D = {InstrD[31:12], 12'b0};

  // ========== DECODE/EXECUTE PIPELINE REGISTER ==========
  // flopenrc: priority reset > clear(FlushE) > enable(~StallE) > hold.
  flopenrc #(32) rd1ereg(clk, reset, FlushE, ~StallE, RD1D, RD1E);
  flopenrc #(32) rd2ereg(clk, reset, FlushE, ~StallE, RD2D, RD2E);
  flopenrc #(32) pcereg(clk, reset, FlushE, ~StallE, PCD, PCE);
  flopenrc #(32) immextereg(clk, reset, FlushE, ~StallE, ImmExtD, ImmExtE);
  flopenrc #(32) pcplus4ereg(clk, reset, FlushE, ~StallE, PCPlus4D, PCPlus4E);
  flopenrc #(5)  rs1ereg(clk, reset, FlushE, ~StallE, Rs1D, Rs1E);
  flopenrc #(5)  rs2ereg(clk, reset, FlushE, ~StallE, Rs2D, Rs2E);
  flopenrc #(5)  rdereg(clk, reset, FlushE, ~StallE, RdD, RdE);

  // Control signal pipeline registers D->E
  flopenrc #(1) regwriteereg(clk, reset, FlushE, ~StallE, RegWriteD, RegWriteE);
  flopenrc #(2) resultsrcereg(clk, reset, FlushE, ~StallE, ResultSrcD, ResultSrcE);
  flopenrc #(1) memwriteereg(clk, reset, FlushE, ~StallE, MemWriteD, MemWriteE);
  flopenrc #(4) alucontrolereg(clk, reset, FlushE, ~StallE, ALUControlD, ALUControlE);
  flopenrc #(3) branchtypeereg(clk, reset, FlushE, ~StallE, BranchTypeD, BranchTypeE);
  flopenrc #(1) alusrcerreg(clk, reset, FlushE, ~StallE, ALUSrcD, ALUSrcE);
  flopenrc #(1) jumpereg(clk, reset, FlushE, ~StallE, JumpD, JumpE);
  flopenrc #(1) branchereg(clk, reset, FlushE, ~StallE, BranchD, BranchE);
  flopenrc #(32) sl12ereg(clk, reset, FlushE, ~StallE, SL12D, SL12E);
  flopenrc #(2) execunitereg(clk, reset, FlushE, ~StallE, ExecUnitD, ExecUnitE);
  flopenrc #(1) isjalrereg(clk, reset, FlushE, ~StallE, IsJalrD, IsJalrE);
  flopenrc #(1) alusrcaereg(clk, reset, FlushE, ~StallE, ALUSrcAD, ALUSrcAE);
  flopenrc #(3) memfunct3ereg(clk, reset, FlushE, ~StallE, MemFunct3D, MemFunct3E);

  // MulDivOp: funct3[1:0] selects mul/div variant
  assign MulDivOpE = BranchTypeE[1:0];

  // ========== EXECUTE STAGE ==========
  // M-stage forwarding: use the value that will actually be written back.
  assign ResultMForward = (ResultSrcM == 2'b00) ? ALUResultM :
                          (ResultSrcM == 2'b01) ? ReadDataM  :
                          (ResultSrcM == 2'b10) ? PCPlus4M   :
                                                  SL12M;

  // Forwarding muxes
  mux3 #(32) forwardaemux(RD1E, ResultW, ResultMForward, ForwardAE, SrcAE_Fwd);
  mux3 #(32) forwardbemux(RD2E, ResultW, ResultMForward, ForwardBE, SrcBE_Fwd);

  // SrcA: auipc uses PC; all other instructions use the (forwarded) register value.
  assign SrcAE = ALUSrcAE ? PCE : SrcAE_Fwd;
  mux2 #(32) srcbmux(SrcBE_Fwd, ImmExtE, ALUSrcE, SrcBE);
  assign WriteDataE = SrcBE_Fwd;

  // ALU
  alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);

  // Multiplier (combinational, single-cycle)
  multiplier mul_unit(SrcAE, SrcBE, MulDivOpE, MulResultE);

  // Divider (iterative, ~34-cycle latency)
  assign divStart = (ExecUnitE == 2'b10) & ~divBusy & ~divDone;
  divider div_unit(clk, reset, SrcAE, SrcBE, MulDivOpE, divStart,
                   DivResultE, divDone, divBusy);

  // Execution unit result mux
  always_comb
    case (ExecUnitE)
      2'b01:   ExecResultE = MulResultE;
      2'b10:   ExecResultE = DivResultE;
      default: ExecResultE = ALUResultE;
    endcase

  // PC target calculation:
  //   branches/jal: PC + ImmExt  (static adder)
  //   jalr:         (rs1 + imm) & ~1  (ALU result, bit 0 masked per RISC-V spec)
  adder pcaddbranch(PCE, ImmExtE, PCBranchE);
  assign PCTargetE = IsJalrE ? (ALUResultE & 32'hFFFFFFFE) : PCBranchE;

  // Branch decision for full RV32I branch family
  assign branchEqE         = (SrcAE_Fwd == SrcBE_Fwd);
  assign branchLtSignedE   = ($signed(SrcAE_Fwd) < $signed(SrcBE_Fwd));
  assign branchLtUnsignedE = (SrcAE_Fwd < SrcBE_Fwd);

  always_comb begin
    case (BranchTypeE)
      3'b000: branchTakenE = branchEqE;             // beq
      3'b001: branchTakenE = ~branchEqE;            // bne
      3'b100: branchTakenE = branchLtSignedE;       // blt
      3'b101: branchTakenE = ~branchLtSignedE;      // bge
      3'b110: branchTakenE = branchLtUnsignedE;     // bltu
      3'b111: branchTakenE = ~branchLtUnsignedE;    // bgeu
      default: branchTakenE = 1'b0;
    endcase
  end

  assign PCSrcE = (BranchE & branchTakenE) | JumpE;

  // ========== EXECUTE/MEMORY PIPELINE REGISTER ==========
  // flopenr with ~StallE so divider stall holds the E/M boundary in place.
  flopenr #(32) aluresultmreg(clk, reset, ~StallE, ExecResultE, ALUResultM);
  flopenr #(32) writedatamreg(clk, reset, ~StallE, WriteDataE, WriteDataM);
  flopenr #(32) pcplus4mreg(clk, reset, ~StallE, PCPlus4E, PCPlus4M);
  flopenr #(5)  rdmreg(clk, reset, ~StallE, RdE, RdM);
  flopenr #(1)  regwritemreg(clk, reset, ~StallE, RegWriteE, RegWriteM);
  flopenr #(1)  memwritemreg(clk, reset, ~StallE, MemWriteE, MemWrite);
  flopenr #(2)  resultsrcmreg(clk, reset, ~StallE, ResultSrcE, ResultSrcM);
  flopenr #(32) sl12mreg(clk, reset, ~StallE, SL12E, SL12M);
  flopenr #(3)  memfunct3mreg(clk, reset, ~StallE, MemFunct3E, MemFunct3M);

  // ========== MEMORY STAGE ==========
  assign MemReadM   = (ResultSrcM == 2'b01);
  assign MemAccessM = MemWrite | MemReadM;

  // ========== MEMORY/WRITEBACK PIPELINE REGISTER ==========
  flopr #(32) aluresultwreg(clk, reset, ALUResultM, ALUResultW);
  flopr #(32) readdatawreg(clk, reset, ReadDataM, ReadDataW);
  flopr #(32) pcplus4wreg(clk, reset, PCPlus4M, PCPlus4W);
  flopr #(5)  rdwreg(clk, reset, RdM, RdW);
  flopr #(1)  regwritewreg(clk, reset, RegWriteM, RegWriteW);
  flopr #(2)  resultsrcwreg(clk, reset, ResultSrcM, ResultSrcW);
  flopr #(32) sl12wreg(clk, reset, SL12M, SL12W);

  // ========== WRITEBACK STAGE ==========
  mux4 #(32) resultmux(ALUResultW, ReadDataW, PCPlus4W, SL12W, ResultSrcW, ResultW);

  // ========== HAZARD UNIT ==========
  hazard hu(Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
            PCSrcE, ResultSrcE, MemAccessM, RegWriteM, RegWriteW,
            ExecUnitE, divDone,
            ForwardAE, ForwardBE, StallF, StallD, StallE, FlushD, FlushE);

endmodule
