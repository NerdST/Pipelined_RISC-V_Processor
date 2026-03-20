; T17: Load-Use Stall WITHOUT Manual NOP - Force real stall behavior
; NO nops inserted; stall logic must insert 1 bubble
; Expected signature: 14 (7 + 7)

main:
        addi x5, x0, 7          # x5 = 7
        sw   x5, 96(x0)         # mem[96] = 7 (initialize test data)
        addi x0, x0, 0          # nop (dmem latency)
        lw   x6, 96(x0)         # x6 = 7 LOAD
        add  x10, x6, x6        # x10 = 14 IMMEDIATE USE (forces stall in hardware)
        sw   x10, 100(x0)       # mem[100] = 14 (proves stall worked)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
