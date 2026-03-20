; T13: Forward E-to-E RS1 - Verify forward to ALU src A from M/W
; NO manual nops inserted; tests that forwarding works
; Expected signature: 15 (5 + 10)

main:
        addi x5, x0, 5          # x5 = 5
        add  x6, x5, x0         # x6 = 5 (result available next cycle)
        add  x7, x6, x0         # x7 = 5 (forward x6 from M stage, NO nop)
        addi x3, x0, 10         # x3 = 10
        add  x10, x7, x3        # x10 = 5 + 10 = 15 (forward x7, proves forwarding)
        sw   x10, 100(x0)       # mem[100] = 15 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
