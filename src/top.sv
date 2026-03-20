module top(input logic clk, reset,
           output logic [31:0] WriteDataM, DataAdrM,
           output logic MemWriteM);

  logic [31:0] PCF, InstrF, ReadDataM;
  logic        MemReadM;

  // Instantiate processor and unified single-port memory.
  riscvprocessor riscvprocessor(clk, reset, PCF, InstrF, MemWriteM, DataAdrM,
              WriteDataM, ReadDataM, MemReadM);

  mem mem(clk, PCF, InstrF, MemReadM, MemWriteM, DataAdrM, WriteDataM, ReadDataM);
endmodule