module datapath(input  logic        clk, reset,
                input  logic [31:0] InstrF,
                output logic [31:0] PCF,
                output logic [31:0] ALUResultM,
                output logic [31:0] WriteDataM,
                input  logic [31:0] ReadDataM,
                output logic        MemWrite,
                output logic        MemReadM);

  // Fetch stage signals
  logic [31:0] PCPlus4F, PCFa, PCTargetE;
  logic        StallF, StallD, FlushD, FlushE;
  logic        PCSrcE;
  
  // Decode stage signals
  logic [31:0] InstrD, PCD, PCPlus4D;
  logic [31:0] RD1D, RD2D, ImmExtD;
  logic [31:0] RD1D_raw, RD2D_raw;
  logic [4:0]  Rs1D, Rs2D, RdD;
  logic        RegWriteD, MemWriteD, JumpD, BranchD;
  logic [1:0]  ResultSrcD, ImmSrcD;
  logic [2:0]  ALUControlD;
    logic [2:0]  BranchTypeD;
  logic        ALUSrcD;
  logic [1:0]  ALUOpD;
  
  // Control signals from controller
  logic [6:0]  OpD;
  logic [2:0]  Funct3D;
  logic        Funct7b5D;
  
  // Execute stage signals
  logic [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  logic [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE;
  logic [31:0] SrcAE_Fwd, SrcBE_Fwd;  // Intermediate signals after forwarding
  logic [4:0]  Rs1E, Rs2E, RdE;
  logic        RegWriteE, MemWriteE, JumpE, BranchE, ZeroE;
  logic [1:0]  ResultSrcE, ForwardAE, ForwardBE;
  logic [2:0]  ALUControlE;
    logic [2:0]  BranchTypeE;
  logic        ALUSrcE;
  logic [31:0] SL12E;
    logic        branchEqE, branchLtSignedE, branchLtUnsignedE, branchTakenE;
  
  // Memory stage signals
  logic [31:0] PCPlus4M, ReadDataMReg, SL12M;
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
  // PC mux and register
  mux2 #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCFa);
  flopenr #(32) pcreg(clk, reset, ~StallF, PCFa, PCF);
  adder pcadd4(PCF, 32'd4, PCPlus4F);
  
  // Instruction comes from memory (input port InstrF)
  
  // ========== FETCH/DECODE PIPELINE REGISTER ==========
  flopenrc #(32) instrdreg(clk, reset, FlushD, ~StallD, InstrF, InstrD);
  flopenrc #(32) pcdreg(clk, reset, FlushD, ~StallD, PCF, PCD);
  flopenrc #(32) pcplus4dreg(clk, reset, FlushD, ~StallD, PCPlus4F, PCPlus4D);
  
  // ========== DECODE STAGE ==========
  // Extract register addresses
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD = InstrD[11:7];
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7b5D = InstrD[30];
    assign BranchTypeD = Funct3D;
  
  // Instantiate controller in Decode stage
  controller ctrl(OpD, Funct3D, Funct7b5D,
                  RegWriteD, ResultSrcD, MemWriteD, JumpD, 
                  BranchD, ALUControlD, ALUSrcD, ImmSrcD);
  
  // Register file
  regfile rf(clk, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D_raw, RD2D_raw);

  // Decode-stage bypass for same-cycle W->D RAW hazards.
  assign RD1D = (RegWriteW && (RdW != 5'b0) && (RdW == Rs1D)) ? ResultW : RD1D_raw;
  assign RD2D = (RegWriteW && (RdW != 5'b0) && (RdW == Rs2D)) ? ResultW : RD2D_raw;
  
  // Extend immediate
  extend ext(InstrD[31:7], ImmSrcD, ImmExtD);
  
  // Shift left 12 for LUI
  logic [31:0] SL12D;
  assign SL12D = {InstrD[31:12], 12'b0};
  
  // ========== DECODE/EXECUTE PIPELINE REGISTER ==========
  floprc #(32) rd1ereg(clk, reset, FlushE, RD1D, RD1E);
  floprc #(32) rd2ereg(clk, reset, FlushE, RD2D, RD2E);
  floprc #(32) pcereg(clk, reset, FlushE, PCD, PCE);
  floprc #(32) immextereg(clk, reset, FlushE, ImmExtD, ImmExtE);
  floprc #(32) pcplus4ereg(clk, reset, FlushE, PCPlus4D, PCPlus4E);
  floprc #(5) rs1ereg(clk, reset, FlushE, Rs1D, Rs1E);
  floprc #(5) rs2ereg(clk, reset, FlushE, Rs2D, Rs2E);
  floprc #(5) rdereg(clk, reset, FlushE, RdD, RdE);
  
  // Control signal pipeline registers D->E
  floprc #(1) regwriteereg(clk, reset, FlushE, RegWriteD, RegWriteE);
  floprc #(2) resultsrcereg(clk, reset, FlushE, ResultSrcD, ResultSrcE);
  floprc #(1) memwriteereg(clk, reset, FlushE, MemWriteD, MemWriteE);
  floprc #(3) alucontrolereg(clk, reset, FlushE, ALUControlD, ALUControlE);
    floprc #(3) branchtypeereg(clk, reset, FlushE, BranchTypeD, BranchTypeE);
  floprc #(1) alusrcerreg(clk, reset, FlushE, ALUSrcD, ALUSrcE);
  floprc #(1) jumpereg(clk, reset, FlushE, JumpD, JumpE);
  floprc #(1) branchereg(clk, reset, FlushE, BranchD, BranchE);
  floprc #(32) sl12ereg(clk, reset, FlushE, SL12D, SL12E);
  
  // ========== EXECUTE STAGE ==========
  // M-stage forwarding must use the value that will be written back, not ALUResult only.
  // This is required for forwarding results of lw, jal (PC+4), and lui.
  assign ResultMForward = (ResultSrcM == 2'b00) ? ALUResultM :
                          (ResultSrcM == 2'b01) ? ReadDataM :
                          (ResultSrcM == 2'b10) ? PCPlus4M :
                                                 SL12M;

  // Forwarding muxes
  mux3 #(32) forwardaemux(RD1E, ResultW, ResultMForward, ForwardAE, SrcAE_Fwd);
  mux3 #(32) forwardbemux(RD2E, ResultW, ResultMForward, ForwardBE, SrcBE_Fwd);
  
  // ALU source muxes
  assign SrcAE = SrcAE_Fwd;  // ALUSrcE is don't care for jal/lui
  mux2 #(32) srcbmux(SrcBE_Fwd, ImmExtE, ALUSrcE, SrcBE);
  assign WriteDataE = SrcBE_Fwd;  // WriteData is the forwarded value before immediate selection
  
  // ALU
  alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);
  
  // PC target calculation
  adder pcaddbranch(PCE, ImmExtE, PCTargetE);
  
    // Branch decision for full RV32I branch family:
    // beq, bne, blt, bge, bltu, bgeu
    assign branchEqE = (SrcAE_Fwd == SrcBE_Fwd);
    assign branchLtSignedE = ($signed(SrcAE_Fwd) < $signed(SrcBE_Fwd));
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
  flopr #(32) aluresultmreg(clk, reset, ALUResultE, ALUResultM);
  flopr #(32) writedatamreg(clk, reset, WriteDataE, WriteDataM);
  flopr #(32) pcplus4mreg(clk, reset, PCPlus4E, PCPlus4M);
  flopr #(5) rdmreg(clk, reset, RdE, RdM);
  flopr #(1) regwritemreg(clk, reset, RegWriteE, RegWriteM);
  flopr #(1) memwritemreg(clk, reset, MemWriteE, MemWrite);
  flopr #(2) resultsrcmreg(clk, reset, ResultSrcE, ResultSrcM);
  flopr #(32) sl12mreg(clk, reset, SL12E, SL12M);
  
  // ========== MEMORY STAGE ==========
  // Memory read/write handled externally
  // Data memory output connected to ReadDataM input
  assign MemReadM = (ResultSrcM == 2'b01);
  assign MemAccessM = MemWrite | MemReadM;
  
  // ========== MEMORY/WRITEBACK PIPELINE REGISTER ==========
  flopr #(32) aluresultwreg(clk, reset, ALUResultM, ALUResultW);
  flopr #(32) readdatawreg(clk, reset, ReadDataM, ReadDataW);
  flopr #(32) pcplus4wreg(clk, reset, PCPlus4M, PCPlus4W);
  flopr #(5) rdwreg(clk, reset, RdM, RdW);
  flopr #(1) regwritewreg(clk, reset, RegWriteM, RegWriteW);
  flopr #(2) resultsrcwreg(clk, reset, ResultSrcM, ResultSrcW);
  flopr #(32) sl12wreg(clk, reset, SL12M, SL12W);
  
  // ========== WRITEBACK STAGE ==========
  // Result mux
  mux4 #(32) resultmux(ALUResultW, ReadDataW, PCPlus4W, SL12W, ResultSrcW, ResultW);
  
  // ========== HAZARD UNIT ==========
  hazard hu(Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
            PCSrcE, ResultSrcE, MemAccessM, RegWriteM, RegWriteW,
            ForwardAE, ForwardBE, StallF, StallD, FlushD, FlushE);
  
endmodule