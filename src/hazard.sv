module hazard(input  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
              input  logic [4:0] RdE, RdM, RdW,
              input  logic       PCSrcE,
              input  logic [1:0] ResultSrcE,
              input  logic       MemAccessM,
              input  logic       RegWriteM, RegWriteW,
              input  logic [1:0] ExecUnitE,  // 2'b10 = divider in Execute
              input  logic       divDone,    // divider result ready (1-cycle pulse)
              output logic [1:0] ForwardAE, ForwardBE,
              output logic       StallF, StallD, StallE, FlushD, FlushE);

  logic lwStall, memStall, divStall;

  // Forwarding logic
  always_comb begin
    // Default: no forwarding
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    // ForwardAE logic
    if (RegWriteM && (RdM != 0) && (RdM == Rs1E))
      ForwardAE = 2'b10; // Forward from Memory stage
    else if (RegWriteW && (RdW != 0) && (RdW == Rs1E))
      ForwardAE = 2'b01; // Forward from Writeback stage

    // ForwardBE logic
    if (RegWriteM && (RdM != 0) && (RdM == Rs2E))
      ForwardBE = 2'b10; // Forward from Memory stage
    else if (RegWriteW && (RdW != 0) && (RdW == Rs2E))
      ForwardBE = 2'b01; // Forward from Writeback stage
  end

  // Stall logic for load-use hazard
  assign lwStall  = (ResultSrcE == 2'b01) && (RdE != 5'b0) && ((RdE == Rs1D) || (RdE == Rs2D));
  assign memStall = MemAccessM;

  // Divider stall: holds F, D, AND the E/M boundary while the iterative divider runs.
  // Released the cycle divDone pulses so the result is captured into the E/M register.
  assign divStall = (ExecUnitE == 2'b10) & ~divDone;

  assign StallF = lwStall | memStall | divStall;
  assign StallD = lwStall | memStall | divStall;
  assign StallE = divStall;  // only div stalls the E/M register; lw/mem insert a bubble instead

  // Flush logic
  assign FlushD = PCSrcE;
  // divStall is intentionally excluded: div stays in Execute, we do NOT flush it to a bubble.
  assign FlushE = lwStall | memStall | PCSrcE;

endmodule
