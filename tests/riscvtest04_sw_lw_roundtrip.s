; T04: SW then LW - Verify store then load from same aligned word
; Expected signature: original x5 = 42

main:
        addi x5, x0, 42         # x5 = 42
        sw   x5, 96(x0)         # mem[96] = 42
        addi x0, x0, 0          # nop (dmem read latency)
        lw   x10, 96(x0)        # x10 = 42 (load from mem)
        sw   x10, 100(x0)       # mem[100] = 42 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
