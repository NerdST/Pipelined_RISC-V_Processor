; T28: LB / LBU - signed vs unsigned byte load (sign extension)
; Store a word with all bytes = 0xFF.
; lb  should sign-extend 0xFF → -1  (0xFFFFFFFF)
; lbu should zero-extend 0xFF → 255 (0x000000FF)
; Compute: lbu_result + lb_result = 255 + (-1) = 254
; Expected signature: 254 at address 100

main:
        addi x5, x0,  -1           # x5 = 0xFFFFFFFF
        sw   x5, 200(x0)           # mem[200..203] = 0xFF 0xFF 0xFF 0xFF
        lb   x6, 200(x0)           # x6 = sign_ext(0xFF) = -1
        lbu  x7, 200(x0)           # x7 = zero_ext(0xFF) = 255
        add  x10, x7, x6           # x10 = 255 + (-1) = 254
        sw   x10, 100(x0)          # mem[100] = 254
        beq  x0, x0, done

done:
        beq  x0, x0, done
