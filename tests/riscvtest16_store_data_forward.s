; T16: Store Data Forward - Verify forwarding to store data path
; NO manual nop after ALU result; store should forward it immediately
; Expected signature: 27

main:
        addi x5, x0, 12         # x5 = 12
        addi x6, x0, 15         # x6 = 15
        add  x7, x5, x6         # x7 = 27
        sw   x7, 96(x0)         # mem[96] = 27 (forward x7 to WriteData, NO nop)
        addi x0, x0, 0          # nop (only for dmem timing)
        lw   x10, 96(x0)        # x10 = 27 (load what was stored)
        addi x0, x0, 0          # nop (only for dmem timing)
        sw   x10, 100(x0)       # mem[100] = 27 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
