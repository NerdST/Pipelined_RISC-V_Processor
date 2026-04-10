; T31: SLL / SLLI / SRL / SRLI - logical shifts
; 0xFF << 4 = 0xFF0 = 4080
; 4080 >> 2 = 1020
; Then register-form: 1 << x (where x=4) = 16; 16 >> x (x=2) = 4
; Combined: 1020 + 4 = 1024
; Expected signature: 1024 at address 100

main:
        addi x5, x0, 0xFF          # x5 = 255
        slli x6, x5, 4             # x6 = 255 << 4 = 4080  (immediate form)
        srli x6, x6, 2             # x6 = 4080 >> 2 = 1020 (immediate form)

        addi x7, x0, 1             # x7 = 1
        addi x8, x0, 4             # x8 = 4  (shift amount in register)
        sll  x9, x7, x8            # x9 = 1 << 4 = 16      (register form)
        addi x8, x0, 2             # x8 = 2
        srl  x9, x9, x8            # x9 = 16 >> 2 = 4      (register form)

        add  x10, x6, x9           # x10 = 1020 + 4 = 1024
        sw   x10, 100(x0)          # mem[100] = 1024
        beq  x0, x0, done

done:
        beq  x0, x0, done
