; T18: Load-Use Stall on RS2 - Dependency through rs2 field
; Expected signature: 3 (10 - 7)

main:
        addi x5, x0, 7          # x5 = 7
        sw   x5, 96(x0)         # mem[96] = 7
        addi x0, x0, 0          # nop (dmem latency)
        lw   x6, 96(x0)         # x6 = 7 LOAD
        addi x3, x0, 10         # x3 = 10
        sub  x10, x3, x6        # x10 = 10 - 7 = 3 (IMMEDIATE USE on rs2)
        sw   x10, 100(x0)       # mem[100] = 3 (proves stall on rs2 worked)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
