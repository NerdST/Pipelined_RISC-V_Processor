; T01: ADDI Smoke Test - Verify reset, fetch, decode, writeback basics
; Expected signature: 5 at address 100

main:
        addi x10, x0, 5         # x10 = 5
        sw   x10, 100(x0)       # mem[100] = 5 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
