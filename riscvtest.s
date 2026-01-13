; 0x0 0x00500513
; 0x4 0x00C00593
; 0x8 0xFF758613
; 0xC 0x00A666B3
; 0x10 0x00D5F733
; 0x14 0x00D70733
; 0x18 0x02C70C63
; 0x1C 0x00D5A6B3
; 0x20 0x00068463
; 0x24 0x00000713
; 0x28 0x00A626B3
; 0x2C 0x00E68633
; 0x30 0x40A60633
; 0x34 0x04C5AA23
; 0x38 0x06002503
; 0x3C 0x00000013
; 0x40 0x00000013
; 0x44 0x00E507B3
; 0x48 0x008005EF
; 0x4C 0x00100513
; 0x50 0x00F50533
; 0x54 0x00018837
; 0x58 0x00F55463
; 0x5C 0x06400513
; 0x60 0x00A7D663
; 0x64 0x00050513
; 0x68 0x00000463
; 0x6C 0x0C800513
; 0x70 0x02A5A023
; 0x74 0x00A50063

main:
#       Instruction             Description             Address         Machine Code
        addi x10, x0,  5        # x10 = 5               0x0             0x00500513
        addi x11, x0,  12       # x9 = 12               0x4             0x00C00593
        addi x12, x11, -9       # x12 = 3               0x8             0xFF758613
        or   x13, x12, x10      # x13 = 7               0xC             0x00A666B3
        and  x14, x11, x13      # x14 = 4               0x10            0x00D5F733
        add  x14, x14, x13      # x14 = 11              0x14            0x00D70733
        beq  x14, x12, end      # NOT taken             0x18            0x02C70C63
        slt  x13, x11, x13      # x13 = 0               0x1C            0x00D5A6B3
        beq  x13, x0, around    # TAKEN                 0x20            0x00068463
        addi x14, x0, 0         # skipped               0x24            0x00000713

around:
        slt  x13, x12, x10      # x13 = 1               0x28            0x00A626B3
        add  x12, x13, x14      # x12 = 12              0x2C            0x00E68633
        sub  x12, x12, x10      # x12 = 7               0x30            0x40A60633
        sw   x12, 84(x11)       # mem[96] = 7           0x34            0x04C5AA23

    # ---- load-use hazard → requires 1–2 nops depending on your core ----
        lw   x10, 96(x0)        # x10 = 7               0x38            0x06002503
        addi x0, x0, 0          # REQUIRED (load-use)   0x3C            0x00000013
        addi x0, x0, 0          # safe second bubble    0x40            0x00000013

        add  x15, x10, x14      # x15 = 7 + 11 = 18     0x44            0x00E507B3

        jal  x11, end           # jump to end, x11 gets ret addr  0x48  0x008005EF
        addi x10, x0, 1         # skipped               0x4C            0x00100513

end:
        add  x10, x10, x15      # x10 = 25              0x50            0x00F50533
        lui  x16, 24            # x16 = 24<<12 = 98304  0x54            0x00018837
        bge  x10, x15, skip     # 25 >= 18 → taken      0x58            0x00F55463
        addi x10, x0, 100       # skipped               0x5C            0x06400513

skip:
        bge  x15, x10, bad      # not taken             0x60            0x00A7D663
        addi x10, x10, 0        # no-op                 0x64            0x00050513
        beq  x0, x0, store      # jump                  0x68            0x00000463
bad:
        addi x10, x0, 200       # skipped               0x6C            0x0C800513

store:
        sw   x10, 0x20(x11)     # mem[100] = 25         0x70            0x02A5A023

done:
        beq x10, x10, done      # infinite loop         0x74            0x00A50063