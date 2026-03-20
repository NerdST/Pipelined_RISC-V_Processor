; T15: Double Forward - Verify forwarding both operands in one cycle
; Expected signature: 35 (15 + 20)

main:
        addi x5, x0, 15         # x5 = 15
        add  x6, x5, x0         # x6 = 15
        addi x7, x0, 20         # x7 = 20
        add  x8, x7, x0         # x8 = 20
        add  x10, x6, x8        # x10 = 15 + 20 = 35 (forward BOTH x6 and x8, no nops)
        sw   x10, 100(x0)       # mem[100] = 35 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
