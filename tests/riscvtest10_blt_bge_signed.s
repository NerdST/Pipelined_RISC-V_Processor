; T10: BLT/BGE Signed - Verify signed comparison branches
; BLT: branch if rs1 < rs2 (signed)
; BGE: branch if rs1 >= rs2 (signed)
; Test: x1=-2, x2=3; blt x1,x2 → taken (because -2 < 3)
; Expected signature: 77

main:
        addi x10, x0, 77        # x10 = 77
        addi x1, x0, -2         # x1 = -2
        addi x2, x0, 3          # x2 = 3
        blt  x1, x2, target     # TAKEN: -2 < 3 (signed)
        addi x10, x0, 1         # WRONG PATH

target:
        sw   x10, 100(x0)       # mem[100] = 77 (final signature)
        beq  x0, x0, done       # infinite loop

done:
        beq  x0, x0, done
