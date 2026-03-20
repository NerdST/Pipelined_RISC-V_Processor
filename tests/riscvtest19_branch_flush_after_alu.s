; T19: Branch Flush After ALU - Verify wrong-path ALU instruction is flushed
; Expected signature: 50 (target path value)

main:
        addi x1, x0, 50         # x1 = 50
        addi x2, x0, 5          # x2 = 5
        beq  x1, x1, target     # TAKEN BRANCH (x1==x1)
        add  x10, x2, x2        # WRONG PATH (must be flushed by hardware)
        beq  x0, x0, done

target:
        sw   x1, 100(x0)        # mem[100] = 50 (prove target path executed)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
