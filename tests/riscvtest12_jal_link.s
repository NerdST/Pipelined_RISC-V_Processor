; T12: JAL Link - Verify jal target and link register (PC+4) writeback
; Expected signature: PC+4 value (address 0x4C = 76 decimal, or whatever PC+4 is)
; This test verifies that x11 (link register) contains return address

main:
        jal  x11, target        # JUMP: x11 = PC+4 (return address)
        addi x10, x0, 1         # WRONG PATH - must be flushed

target:
        sw   x11, 100(x0)       # mem[100] = return address (proves link reg works)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
