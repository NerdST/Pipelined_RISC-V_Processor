; T06: Word Alignment - Confirm word indexing assumptions
; Expected signature: 33 stored at word-aligned address 100

main:
        addi x5, x0, 33         # x5 = 33
        sw   x5, 0(x0)          # mem[0] = 33
        addi x0, x0, 0          # nop (dmem latency)
        lw   x10, 0(x0)         # x10 = 33
        sw   x10, 100(x0)       # mem[100] = 33 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
