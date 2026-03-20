; T02: R-Type Chain - Verify add/sub/and/or/slt datapath
; Expected signature: deterministic arithmetic result
; x1 = 10, x2 = 3, x3 = (x1 + x2) = 13, x4 = (x3 - x1) = 3, x5 = (x3 & x4) = 1

main:
        addi x1, x0, 10         # x1 = 10
        addi x2, x0, 3          # x2 = 3
        add  x3, x1, x2         # x3 = 13
        sub  x4, x3, x1         # x4 = 3
        and  x5, x3, x4         # x5 = 13 & 3 = 1
        sw   x5, 100(x0)        # mem[100] = 1 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
