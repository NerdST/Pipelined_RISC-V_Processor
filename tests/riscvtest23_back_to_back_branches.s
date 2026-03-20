; T23: Back-to-Back Branches - Stress consecutive control redirects and flush timing
; Expected signature: 72 (target_b value)

main:
        addi x1, x0, 72         # x1 = 72
        beq  x1, x1, target_a   # TAKEN: jump to target_a
        addi x10, x0, 1         # WRONG PATH

target_a:
        addi x2, x0, 1          # x2 = 1
        beq  x2, x2, target_b   # TAKEN: jump to target_b
        addi x10, x0, 2         # WRONG PATH

target_b:
        sw   x1, 100(x0)        # mem[100] = 72 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
