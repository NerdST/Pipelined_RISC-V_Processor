; T14: Forward E-to-E RS2 - Verify forward to ALU src B
; NO manual nops; forward x6 to rs2 position
; Expected signature: 5 (10 - 5)

main:
        addi x5, x0, 10         # x5 = 10
        add  x6, x5, x0         # x6 = 10 (result available next cycle)
        addi x3, x0, 5          # x3 = 5
        sub  x7, x3, x6         # x7 = 5 - 10 = -5 (forward x6 to rs2, NO nop)
        addi x10, x7, 5         # x10 = -5 + 5 = 0 (forward x7, proves rs2 forwarding)
        sw   x10, 100(x0)       # mem[100] = 0 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
