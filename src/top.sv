module top(input logic clk, reset,
           output logic [31:0] WriteDataM, DataAdrM,
           output logic MemWriteM);

  logic [31:0] PCF, InstrF, ReadDataM;
  logic        MemReadM;
  logic [2:0]  MemFunct3M;

  riscvprocessor riscvprocessor(clk, reset, PCF, InstrF, MemWriteM, DataAdrM,
              WriteDataM, ReadDataM, MemReadM, MemFunct3M);

  mem mem(clk, PCF, InstrF, MemReadM, MemWriteM, DataAdrM, WriteDataM, ReadDataM, MemFunct3M);
endmodule
