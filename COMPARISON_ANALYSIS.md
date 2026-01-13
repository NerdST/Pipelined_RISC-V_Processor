# RISC-V 5-Stage Pipeline: Your Implementation vs. Reference (EmJunaid)

## Executive Summary
Your implementation is **functionally sound** but **lacks critical hazard management features** and **has incomplete instruction decoding logic**. The reference implementation is more robust with better forwarding paths and more comprehensive ALU operations.

---

## 1. CONTROLLER/DECODER DIFFERENCES

### Your Implementation
- **Simple 2-stage decoding**: Opcode decoding + ALU operation selection
- **Limited ALU control signals**: 3-bit ALUControl
- **Limited branch support**: Only handles beq, no bne, blt, bge variants
- **Single result source type system**: 2-bit ResultSrc for lw/sw/jal

```systemverilog
// Your approach - ALU control only has 3 bits
output logic [2:0] ALUControl;
```

### Reference Implementation  
- **Comprehensive instruction decoding**: 17-bit checker combining opcode, funct3, and funct7
- **Extended ALU control**: 5-bit ALUControlD (supports 32 operations)
- **Full B-type branch support**: beq, bne, blt, bge, bltu, bgeu
- **U-type support**: For upper immediate loading

```verilog
// Reference approach - 5-bit ALU control for more operations
output reg [4:0] ALUControlD;

// Comprehensive checker for precise instruction identification
wire [16:0] checker;
assign checker = {{OP},{funct3},{funct77}};
```

**Required Changes:**
- [ ] Expand ALUControl from 3-bit to 5-bit
- [ ] Add full branch type support (bne, blt, bge, bltu, bgeu)
- [ ] Implement proper funct3-based branch condition evaluation

---

## 2. ALU MODULE DIFFERENCES

### Your Implementation
- **Basic operations only**: add, sub, and, or, xor, slt, sll, srl
- **Single zero flag**: For beq only
- **3-bit control input**

```systemverilog
module alu(input [31:0] a, b,
           input [2:0] alucontrol,
           output [31:0] result,
           output zero);
```

### Reference Implementation
- **16+ operations**: add, sub, mul, div, sll, srl, and, or, xor, nor, nand, xnor, sgt, seq
- **Branch-aware zero flag**: Evaluates branch conditions using funct3
- **5-bit control input** for granular operation selection
- **Carry out flag** for overflow detection

```verilog
module alu(
    input [31:0] SrcAE, SrcBE,
    input [4:0] ALUControlE,
    input [2:0] funct3E,        // Branch condition evaluation
    output reg [31:0] ALUResult,
    output reg CarryOut,
    output reg ZeroE
);
```

**Required Changes:**
- [ ] Expand ALU to 5-bit control
- [ ] Add branch condition logic via funct3
- [ ] Implement: mul, div, nor, nand, xnor, sgt (set greater than)
- [ ] Add CarryOut flag for overflow

---

## 3. IMMEDIATE EXTENSION DIFFERENCES

### Your Implementation
```systemverilog
module extend(input logic [31:7] instr,
              input logic [1:0] immsrc,
              output logic [31:0] immext);
  
  case(immsrc) 
    2'b00: immext = {{20{instr[31]}}, instr[31:20]};        // I-type
    2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type
    2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
    2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
  endcase
```

### Reference Implementation
```verilog
module sign_extend (
    input [24:0] Imm,
    input [2:0] ImmSrcD,        // 3-bit instead of 2-bit
    output reg [31:0] ImmExtD
);
  
  case(ImmSrcD)
    3'b000: ImmExtD = {{20{Imm[24]}}, Imm[24:13]};                    // I-type
    3'b001: ImmExtD = {{20{Imm[24]}}, Imm[24:18], Imm[4:0]};          // S-type
    3'b010: ImmExtD = {{20{Imm[24]}}, Imm[0], Imm[23:18], Imm[4:1], 1'b0}; // B-type
    3'b011: ImmExtD = {{12{Imm[24]}}, Imm[12:5], Imm[13], Imm[23:14], 1'b0}; // J-type
    3'b100: ImmExtD = {Imm[24:5],12'b000000000000};                   // U-type (NEW)
  endcase
```

**Required Changes:**
- [ ] Expand ImmSrc from 2-bit to 3-bit
- [ ] Add U-type (upper immediate) support
- [ ] **Fix B-type immediate encoding** (your current encoding appears incorrect)

---

## 4. HAZARD UNIT DIFFERENCES

### Your Implementation
```systemverilog
module hazard(...
  logic lwStall;
  
  // Forwarding: only 2 sources (Memory, Writeback)
  if (RegWriteM && (RdM != 0) && (RdM == Rs1E))
    ForwardAE = 2'b10; // From Memory
  else if (RegWriteW && (RdW != 0) && (RdW == Rs1E))
    ForwardAE = 2'b01; // From Writeback
```

### Reference Implementation
```verilog
module hazard_unit(
  // Same forwarding logic but with explicit edge cases
  if (((Rs1E == RdM) && RegWriteM) && (Rs1E != 0) )
    ForwardAE = 2'b10;
  else if ( ((Rs1E == RdW) && RegWriteW) && (Rs1E != 0) )
    ForwardAE = 2'b01;
```

**Status**: ✅ Your hazard unit logic is **essentially equivalent** to the reference. Minor stylistic differences only.

---

## 5. PIPELINE REGISTER ARCHITECTURE

### Your Implementation
- **Combined control signals in single modules**
- Uses individual `flopr`, `floprc`, `flopenrc` modules for each signal
- All pipeline registers inside datapath module

```systemverilog
// Your style - individual registers per signal
floprc #(32) rd1ereg(clk, reset, FlushE, RD1D, RD1E);
floprc #(32) rd2ereg(clk, reset, FlushE, RD2D, RD2E);
floprc #(1) regwriteereg(clk, reset, FlushE, RegWriteD, RegWriteE);
```

### Reference Implementation
- **Dedicated pipeline register modules** (2nd_register, 3rd_register, 4th_register)
- Modules group related signals logically
- Separate modules for each pipeline stage
- Better modularity and maintainability

```verilog
// Reference style - grouped in dedicated modules
module Second_register (
    input [31:0] PCD, ImmExtD, PCPlus4D, RD1, RD2,
    input [4:0] RdD, Rs1D, Rs2D,
    input [2:0] funct3,
    input RegWriteD, MemWriteD, JumpD, BranchD,
    ...
    output reg [31:0] PCE, ImmExtE, PCPlus4E, RD1E, RD2E,
    output reg [4:0] RdE, Rs1E, Rs2E,
    ...
);
```

**Status**: ⚠️ **Minor architectural difference** - Both work, but reference is cleaner for large designs.

---

## 6. DATAPATH ORGANIZATION

### Your Implementation
- **All logic in single `datapath` module** (400+ lines)
- Complex signal interconnection
- Harder to trace signal flow
- PC mux inside datapath

```systemverilog
module datapath(...
  // PC calculation
  mux2 #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCFa);
  flopenr #(32) pcreg(clk, reset, ~StallF, PCFa, PCF);
  adder pcadd4(PCF, 32'd4, PCPlus4F);
  
  // Decode stage
  regfile rf(...);
  extend ext(...);
  
  // Execute stage
  mux3 #(32) forwardaemux(...);
  // ... 100+ more lines
```

### Reference Implementation
- **Hierarchical sub-modules** for each major function:
  - `Adress_Generator` - PC and branch target
  - `Instruction_Memory` - Instruction fetch
  - `Instruction_Fetch` - Decode instruction fields
  - `Register_File` - Register operations
  - `PCTarget` - Branch/jump targeting
  - `alu` - Arithmetic operations
  - Separate register modules

```verilog
module main (
    ...
    Adress_Generator i_ag (...);
    Instruction_Memory i_im (...);
    first_register i_1 (...);
    PCPlus4 i_pcp4 (...);
    Instruction_Fetch i_iff (...);
    Register_File i_rf (...);
    sign_extend i_se (...);
    Second_register i_2 (...);
    // ... much cleaner hierarchy
```

**Status**: ⚠️ **Architectural limitation** - Your single-module approach is harder to debug and extend.

---

## 7. FORWARDING/MULTIPLEXER DIFFERENCES

### Your Implementation
```systemverilog
// Single 3-input mux for forwarding
mux3 #(32) forwardaemux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAE_Fwd);

// Limited forwarding sources
assign WriteDataE = SrcBE_Fwd;
```

### Reference Implementation
```verilog
// More comprehensive multiplexing for SrcA
mux5 #(32) muxxx (
    .RD1E(RD1E),
    .ResultW(ResultW),
    .ALUResultM(ALUResultM),
    .ForwardAE(ForwardAE),
    .SrcAE(SrcAE)
);

// Separate multiplexer for WriteData
mux4 #(32) muxxxxx (
    .RD2E(RD2E),
    .ResultW(ResultW),
    .ALUResultM(ALUResultM),
    .ForwardBE(ForwardBE),
    .WriteDataE(WriteDataE)
);
```

**Status**: ⚠️ **Your mux3 may be insufficient** for all forwarding scenarios. Reference uses mux4 and mux5 for more flexible routing.

---

## SUMMARY OF REQUIRED CHANGES

### **HIGH PRIORITY** (Critical for full functionality)
1. **Expand Controller**:
   - Change ImmSrc from 2-bit to 3-bit
   - Add U-type immediate support
   - Add full B-type branch variants (bne, blt, bge, bltu, bgeu)
   - Expand ALUControl from 3-bit to 5-bit

2. **Enhance ALU**:
   - Add 5-bit control input
   - Implement branch condition evaluation using funct3
   - Add mul, div, nor, nand, xnor operations
   - Add CarryOut and proper ZeroE for branches

3. **Update Immediate Extension**:
   - Support U-type immediate format
   - Verify B-type bit extraction is correct

4. **Update Hazard Unit Interface**:
   - Pass funct3E to hazard unit for branch condition checks
   - Adjust forwarding based on branch type

### **MEDIUM PRIORITY** (Code quality)
5. **Refactor Datapath**:
   - Extract pipeline registers into separate modules
   - Create dedicated modules for address generation, instruction decoding
   - Improve modularity for easier debugging

6. **Improve Multiplexing**:
   - Consider mux4/mux5 variants for more complex forwarding
   - Document all forwarding paths

### **LOW PRIORITY** (Nice-to-have)
7. Add output signals for register file contents (like reference's checkx1-checkx6)
8. Add data memory debugging outputs

---

## IMPLEMENTATION SEQUENCE

1. **Phase 1**: Update Controller and ALU decoders
2. **Phase 2**: Expand ALU operations and branch handling
3. **Phase 3**: Add U-type immediate support
4. **Phase 4** (Optional): Refactor into hierarchical modules
5. **Phase 5**: Comprehensive testing with branch variants

