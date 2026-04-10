; T25: M-extension divide + stall + post-stall forwarding
; Verifies that:
;   1. The pipeline correctly stalls (~34 cycles) while the divider runs.
;   2. The instruction immediately after div receives the correct forwarded
;      result from the M stage once the stall releases (no NOP needed).
;
; Expected signature: 6
;   x5 = 15, x6 = 5
;   x7 = div(x5, x6) = 3   (stalls pipeline ~34 cycles)
;   x8 = add(x7, x7) = 6   <- forward from M stage after stall releases

main:
        addi x5, x0, 15         # x5 = 15
        addi x6, x0, 5          # x6 = 5
        div  x7, x5, x6         # x7 = 3  (15 / 5, ~34-cycle stall)
        add  x8, x7, x7         # x8 = 6  (forward x7 from M stage, no NOP)
        sw   x8, 100(x0)        # mem[100] = 6 (final signature)
        beq  x0, x0, done
done:
        beq  x0, x0, done
