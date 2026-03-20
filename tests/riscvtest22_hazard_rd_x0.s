; T22: Hazard with rd=x0 - Ensure rd=x0 does not trigger false stalls
; Load into x0 should not trigger false load-use hazard
; Expected signature: deterministic value

main:
        addi x5, x0, 42         # x5 = 42
        sw   x5, 96(x0)         # mem[96] = 42
        addi x0, x0, 0          # nop (dmem latency)
        lw   x0, 96(x0)         # x0 = 42 (but x0 always stays 0, no hazard)
        add  x10, x5, x5        # x10 = 84 (x5 still 42, should not stall on x0)
        sw   x10, 100(x0)       # mem[100] = 84 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
