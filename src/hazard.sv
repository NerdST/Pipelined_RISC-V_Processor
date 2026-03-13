module hazard(input  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
              input  logic [4:0] RdE, RdM, RdW,
              input  logic       PCSrcE,
              input  logic [1:0] ResultSrcE,
              input  logic       RegWriteM, RegWriteW,
              output logic [1:0] ForwardAE, ForwardBE,
              output logic       StallF, StallD, FlushD, FlushE);

  logic lwStall;

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
  assign lwStall = ResultSrcE[0] && ((RdE == Rs1D) || (RdE == Rs2D));
  assign StallF = lwStall;
  assign StallD = lwStall;

  // Flush logic
  assign FlushD = PCSrcE;  // Flush decode stage on branch/jump
  assign FlushE = lwStall | PCSrcE;  // Flush execute on stall or branch/jump

endmodule