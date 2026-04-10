; T27: AUIPC - rd = PC + (imm << 12)
; auipc at PC=8 with imm=0 stores 8 in x10.
; Two nops before auipc so it lands at PC=8 (a non-zero, easy-to-verify value).
; Expected signature: 8 at address 100

main:
        nop                        # PC=0
        nop                        # PC=4
        auipc x10, 0               # PC=8  → x10 = 8 + (0<<12) = 8
        sw    x10, 100(x0)         # mem[100] = 8
        beq   x0, x0, done

done:
        beq   x0, x0, done
