; T08: BEQ Not Taken - Verify BEQ fall-through
; Expected signature: 44

main:
        addi x10, x0, 44        # x10 = 44
        addi x1, x0, 5          # x1 = 5
        addi x2, x0, 3          # x2 = 3
        beq  x1, x2, target     # NOT taken: x1 != x2
        sw   x10, 100(x0)       # mem[100] = 44 (fall-through path)
        beq  x0, x0, done       # infinite loop

target:
        addi x10, x0, 99        # WRONG PATH
        beq  x0, x0, done

done:
        beq  x0, x0, done
