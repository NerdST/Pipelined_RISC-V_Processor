; T32: XOR / XORI / SLTU / SLTIU / SLT / SLTI
; xori: 15 ^ 5 = 10
; xor:  15 ^ 10 = 5
; sltu: (5 <u 15) = 1
; sltiu: (5 <u 20) = 1
; slt:  (-1 <s 1) = 1   (signed: -1 < 1 is true; unsigned: 0xFFFFFFFF < 1 is false)
; slti: (-1 <s 0) = 1
; Sum: 10 + 5 + 1 + 1 + 1 + 1 = 19
; Expected signature: 19 at address 100

main:
        addi x5, x0, 15            # x5 = 15
        xori x6, x5, 5             # x6 = 15 ^ 5  = 10
        xor  x7, x5, x6            # x7 = 15 ^ 10 = 5
        sltu x8, x7, x5            # x8 = (5 <u 15)  = 1
        addi x9, x0, 20
        sltiu x11, x7, 20          # x11 = (5 <u 20) = 1

        addi x12, x0, -1           # x12 = -1 = 0xFFFFFFFF
        addi x13, x0, 1
        slt  x14, x12, x13         # x14 = (-1 <s 1) = 1  (signed)
        slti x15, x12, 0           # x15 = (-1 <s 0) = 1  (signed immediate)

        add  x10, x6, x7           # 10 + 5 = 15
        add  x10, x10, x8          # 15 + 1 = 16
        add  x10, x10, x11         # 16 + 1 = 17
        add  x10, x10, x14         # 17 + 1 = 18
        add  x10, x10, x15         # 18 + 1 = 19
        sw   x10, 100(x0)          # mem[100] = 19
        beq  x0, x0, done

done:
        beq  x0, x0, done
