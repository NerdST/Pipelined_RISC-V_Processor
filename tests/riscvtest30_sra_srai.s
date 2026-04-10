; T30: SRA / SRAI - arithmetic right shift preserves sign bit
; Load 0x80000000 (most-negative int). Shift right arithmetic by 31.
;   srai → 0xFFFFFFFF (-1) — sign bit propagated into all positions
;   srli would give 0x00000001 (+1) — zero-filled
; Add 2 to the srai result: -1 + 2 = 1.
; If srai was wrong (acted like srli): 1 + 2 = 3.
; Also test register-form sra with a smaller value: -16 >> 2 = -4.
;   sra result: -4. Add 5 = 1.
; Combined: (srai result + 2) + (sra result + 5) = 1 + 1 = 2
; Expected signature: 2 at address 100

main:
        lui  x5, 0x80000            # x5 = 0x80000000 (INT_MIN)
        srai x6, x5, 31             # x6 = 0xFFFFFFFF = -1  (arithmetic shift)
        addi x6, x6, 2              # x6 = 1

        addi x7, x0, -16            # x7 = -16 = 0xFFFFFFF0
        addi x8, x0, 2              # x8 = shift amount
        sra  x9, x7, x8             # x9 = -16 >> 2 = -4  (register form)
        addi x9, x9, 5              # x9 = 1

        add  x10, x6, x9            # x10 = 1 + 1 = 2
        sw   x10, 100(x0)           # mem[100] = 2
        beq  x0, x0, done

done:
        beq  x0, x0, done
