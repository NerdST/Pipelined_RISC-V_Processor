; T11: BLTU/BGEU Unsigned - Verify unsigned comparison branches
; BLTU: branch if rs1 < rs2 (unsigned)
; Test with values that differ in signed vs unsigned interpretation
; x1 = 2^31 + 1 (large unsigned, negative signed), x2 = 3
; bltu x2, x1 → taken (3 < 2^31+1 unsigned)
; Expected signature: 88

main:
        addi x10, x0, 88        # x10 = 88
        lui  x1, 524288         # x1 = 0x80000000
        addi x1, x1, 1          # x1 = 0x80000001 (large unsigned value)
        addi x2, x0, 3          # x2 = 3
        bltu x2, x1, target     # TAKEN: 3 < 0x80000001 (unsigned)
        addi x10, x0, 1         # WRONG PATH

target:
        sw   x10, 100(x0)       # mem[100] = 88 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
