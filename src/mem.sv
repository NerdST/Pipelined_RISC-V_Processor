module mem(input  logic        clk,
            input  logic [31:0] pcAddrF,
            output logic [31:0] instrF,
            input  logic        memReadM,
            input  logic        memWriteM,
            input  logic [31:0] dataAddrM,
            input  logic [31:0] writeDataM,
            output logic [31:0] readDataM,
            input  logic [2:0]  memFunct3M);  // funct3 from M stage: selects width and sign

  logic [31:0] RAM[4095:0];
  logic        memAccessM;

  assign memAccessM = memReadM | memWriteM;

// synthesis translate_off
  string mem_file;
initial begin
  if (!$value$plusargs("MEM=%s", mem_file))
    mem_file = "../../tests/riscvtest01_addi_smoke.mem";
  $display("[mem] loading image: %s", mem_file);
$display("Current directory:");
  $system("pwd");
  $readmemh(mem_file, RAM);
end
// synthesis translate_on

  // ---- Combinational read ----
  // During MEM-stage access the unified single-port RAM is dedicated to the data path.
  always_comb begin
    instrF    = 32'h00000013; // NOP bubble while data path owns RAM
    readDataM = 32'b0;

    if (memAccessM) begin
      // Full word read; byte/half extraction happens below.
      logic [31:0] raw;
      raw = RAM[dataAddrM[31:2]];

      case (memFunct3M)
        3'b000: // lb — signed byte
          case (dataAddrM[1:0])
            2'b00: readDataM = {{24{raw[7]}},  raw[7:0]};
            2'b01: readDataM = {{24{raw[15]}}, raw[15:8]};
            2'b10: readDataM = {{24{raw[23]}}, raw[23:16]};
            2'b11: readDataM = {{24{raw[31]}}, raw[31:24]};
          endcase
        3'b001: // lh — signed halfword
          case (dataAddrM[1])
            1'b0: readDataM = {{16{raw[15]}}, raw[15:0]};
            1'b1: readDataM = {{16{raw[31]}}, raw[31:16]};
          endcase
        3'b100: // lbu — unsigned byte
          case (dataAddrM[1:0])
            2'b00: readDataM = {24'b0, raw[7:0]};
            2'b01: readDataM = {24'b0, raw[15:8]};
            2'b10: readDataM = {24'b0, raw[23:16]};
            2'b11: readDataM = {24'b0, raw[31:24]};
          endcase
        3'b101: // lhu — unsigned halfword
          case (dataAddrM[1])
            1'b0: readDataM = {16'b0, raw[15:0]};
            1'b1: readDataM = {16'b0, raw[31:16]};
          endcase
        default: readDataM = raw; // lw (3'b010) — full word
      endcase
    end else begin
      instrF = RAM[pcAddrF[31:2]];
    end
  end

  // ---- Synchronous write ----
  always_ff @(posedge clk)
    if (memWriteM)
      case (memFunct3M[1:0])
        2'b00: // sb — store byte
          case (dataAddrM[1:0])
            2'b00: RAM[dataAddrM[31:2]][7:0]   <= writeDataM[7:0];
            2'b01: RAM[dataAddrM[31:2]][15:8]  <= writeDataM[7:0];
            2'b10: RAM[dataAddrM[31:2]][23:16] <= writeDataM[7:0];
            2'b11: RAM[dataAddrM[31:2]][31:24] <= writeDataM[7:0];
          endcase
        2'b01: // sh — store halfword
          case (dataAddrM[1])
            1'b0: RAM[dataAddrM[31:2]][15:0]  <= writeDataM[15:0];
            1'b1: RAM[dataAddrM[31:2]][31:16] <= writeDataM[15:0];
          endcase
        default: RAM[dataAddrM[31:2]] <= writeDataM; // sw — store word
      endcase
endmodule
