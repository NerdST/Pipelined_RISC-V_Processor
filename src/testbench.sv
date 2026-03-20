module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;
  logic [31:0] RAM [4095:0];
  logic [31:0] PCF, InstrF;
  
  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);

  // Expose unified memory contents as a single global for waveform debug.
  always_comb RAM = dut.mem.RAM;
  always_comb PCF = dut.PCF;
  always_comb InstrF = dut.InstrF;
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if (MemWrite) begin
        if (DataAdr === 32'd100) begin
          $display("FINAL_SIGNATURE: DataAdr=%0d WriteData=%0d", DataAdr, WriteData);
          $stop;
        end
      end
    end
endmodule