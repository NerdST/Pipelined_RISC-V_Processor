; T09: BNE Taken - Verify BNE (branch not-equal) comparator
; Expected signature: 55 (target path where x1 != x2)

main:
        addi x10, x0, 55        # x10 = 55
        addi x1, x0, 5          # x1 = 5
        addi x2, x0, 3          # x2 = 3
        bne  x1, x2, target     # TAKEN: x1 != x2
        addi x10, x0, 1         # WRONG PATH - must be flushed

target:
        sw   x10, 100(x0)       # mem[100] = 55 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
