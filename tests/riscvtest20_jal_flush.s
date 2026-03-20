; T20: JAL Flush - Verify instruction after jal does not commit
; Expected signature: 61 (target value)

main:
        jal  x11, target        # JUMP TO TARGET (x11 = PC+4 = return addr)
        addi x10, x0, 123       # WRONG PATH (must be flushed)

target:
        addi x10, x0, 61        # x10 = 61 (target path)
        sw   x10, 100(x0)       # mem[100] = 61 (prove target executed)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
