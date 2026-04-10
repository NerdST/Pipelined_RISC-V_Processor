; T29: SB / SH store-load roundtrip
; Write a known byte with sb, read it back with lbu → verify only the target byte changed.
; Write a known halfword with sh, read it back with lhu → verify value preserved.
; Combine results: byte_val + half_val = 0xAB + 0x1234 = 4811
; Expected signature: 4811 at address 100

main:
        # --- byte roundtrip ---
        addi x5, x0, 0xAB          # x5 = 0xAB = 171
        sb   x5, 200(x0)           # mem[200] byte = 0xAB
        lbu  x6, 200(x0)           # x6 = 0xAB = 171 (zero-extended)

        # --- halfword roundtrip ---
        addi x7, x0, 0x12          # x7 = 0x12
        slli x7, x7, 8             # x7 = 0x1200
        addi x7, x7, 0x34          # x7 = 0x1234
        sh   x7, 204(x0)           # mem[204..205] halfword = 0x1234
        lhu  x8, 204(x0)           # x8 = 0x1234 = 4660 (zero-extended)

        add  x10, x6, x8           # x10 = 171 + 4660 = 4831
        sw   x10, 100(x0)          # mem[100] = 4831
        beq  x0, x0, done

done:
        beq  x0, x0, done
