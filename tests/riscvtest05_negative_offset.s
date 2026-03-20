; T05: Negative Offset - Verify sign-extension of I/S immediates
; Use base x11 = 100, then lw x10, -4(x11) = lw x10, 96(x0)
; Expected signature: value stored at address 96

main:
        addi x5, x0, 17         # x5 = 17
        addi x11, x0, 100       # x11 = 100 (base for negative offset)
        sw   x5, -4(x11)        # mem[96] = 17
        addi x0, x0, 0          # nop (dmem latency)
        lw   x10, -4(x11)       # x10 = 17
        sw   x10, 0(x11)        # mem[100] = 17 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
