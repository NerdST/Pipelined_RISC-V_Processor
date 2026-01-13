# riscvtest.s
# Sarah.Harris@unlv.edu
# David_Harris@hmc.edu
# 27 Oct 2020
#
# Test the RISC-V processor.  
#  add, sub, and, or, slt, addi, lw, sw, beq, jal
# If successful, it should write the value 25 to address 100

# riscvtest_hazards.s
# Modified to handle 5-stage pipeline hazards (No Forwarding)

#       Assembly code           Description             Address      Machine Code
main:   addi x2, x0, 5          # x2 = 5                0x00         0x00500113        
        addi x3, x0, 12         # x3 = 12               0x04         0x00C00193

        # HAZARD: x3 used in next instruction
        addi x0, x0, 0          # NOP                   0x08         0x00000013
        addi x0, x0, 0          # NOP                   0x0C         0x00000013
        addi x7, x3, -9         # x7 = (12 - 9) = 3     0x10         0xFF718393

        # HAZARD: x7 used in next instruction
        addi x0, x0, 0          # NOP                   0x14         0x00000013
        addi x0, x0, 0          # NOP                   0x18         0x00000013
        or   x4, x7, x2         # x4 = (3 OR 5) = 7     0x1C         0x0023E233

        # HAZARD: x4 used in next instruction
        addi x0, x0, 0          # NOP                   0x20         0x00000013
        addi x0, x0, 0          # NOP                   0x24         0x00000013
        and  x5, x3, x4         # x5 = (12 AND 7) = 4   0x28         0x0041F2B3

        # HAZARD: x5 used in next instruction
        addi x0, x0, 0          # NOP                   0x2C         0x00000013
        addi x0, x0, 0          # NOP                   0x30         0x00000013
        add  x5, x5, x4         # x5 = (4 + 7) = 11     0x34         0x004282B3

        # HAZARD: x5 used in beq comparison
        addi x0, x0, 0          # NOP                   0x38         0x00000013
        addi x0, x0, 0          # NOP                   0x3C         0x00000013
        beq  x5, x7, end        # shouldn't be taken    0x40         0x04728E63

        slt  x4, x3, x4         # x4 = (12 < 7) = 0     0x44         0x0041A233

        # HAZARD: x4 used in beq comparison
        addi x0, x0, 0          # NOP                   0x48         0x00000013
        addi x0, x0, 0          # NOP                   0x4C         0x00000013
        beq  x4, x0, around     # should be taken       0x50         0x00020463

        addi x5, x0, 0          # (Skipped or flushed if branch taken) 0x54 0x00000293

around: slt  x4, x7, x2         # x4 = (3 < 5)  = 1     0x58         0x0023A233

        # HAZARD: x4 used in next instruction
        addi x0, x0, 0          # NOP                   0x5C         0x00000013
        addi x0, x0, 0          # NOP                   0x60         0x00000013
        add  x7, x4, x5         # x7 = (1 + 11) = 12    0x64         0x005203B3

        # HAZARD: x7 used in next instruction
        addi x0, x0, 0          # NOP                   0x68         0x00000013
        addi x0, x0, 0          # NOP                   0x6C         0x00000013
        sub  x7, x7, x2         # x7 = (12 - 5) = 7     0x70         0x402383B3

        # HAZARD: x7 used in sw (store data)
        # Even though sw uses x7 in MEM, it reads it in ID
        addi x0, x0, 0          # NOP                   0x74         0x00000013
        addi x0, x0, 0          # NOP                   0x78         0x00000013
        sw   x7, 84(x3)         # [96] = 7              0x7C         0x0471AA23

        lw   x2, 96(x0)         # x2 = [96] = 7         0x80         0x06002103

        # HAZARD: Load-Use on x2
        addi x0, x0, 0          # NOP                   0x84         0x00000013
        addi x0, x0, 0          # NOP                   0x88         0x00000013
        add  x9, x2, x5         # x9 = (7 + 11) = 18    0x8C         0x005104B3

        # HAZARD: x9 used at 'end' target
        # Path: add x9 -> jal -> end: add x2...
        # 'jal' provides 1 cycle gap. We need 2 cycles total gap.
        # So we add 1 addi x0, x0, 0 here before the jump.
        addi x0, x0, 0          # NOP                   0x90         0x00000013
        jal  x3, end            # jump to end           0x94         0x008001EF

        addi x2, x0, 1          # shouldn't happen      0x98         0x00100113

end:    add  x2, x2, x9         # x2 = (7 + 18) = 25    0x9C         0x00910133
        sw   x2, 0x20(x3)       # mem[100] = 25         0xA0         0x0221A023

done:   beq  x2, x2, done       # infinite loop         0xA4         0x00210063