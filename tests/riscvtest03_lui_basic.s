; T03: LUI Basic - Verify LUI shift-left-12 and writeback
; Expected signature: 24 << 12 = 98304

main:
        lui  x10, 24            # x10 = 24 << 12 = 98304
        sw   x10, 100(x0)       # mem[100] = 98304 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
