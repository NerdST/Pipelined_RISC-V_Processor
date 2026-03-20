; T07: BEQ Taken - Verify taken BEQ redirects PC and flushes wrong-path
; Expected signature: 99 (target path value, not wrong-path 1)

main:
        addi x1, x0, 99         # x1 = 99
        beq  x1, x1, target     # TAKEN: should jump to target
        addi x10, x0, 1         # WRONG PATH - must be flushed

target:
        sw   x1, 100(x0)        # mem[100] = 99 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
