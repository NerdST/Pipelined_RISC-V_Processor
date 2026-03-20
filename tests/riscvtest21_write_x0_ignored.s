; T21: Write x0 Ignored - Ensure writes to x0 are ignored
; Expected signature: 0

main:
        addi x0, x0, 7          # x0 is always 0 (register constraint)
        addi x10, x0, 0         # x10 = 0 (copied from x0)
        sw   x10, 100(x0)       # mem[100] = 0 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
