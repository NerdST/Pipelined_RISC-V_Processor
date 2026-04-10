; T24: M-extension multiply + forwarding
; Verifies that mul produces the correct result and that the result
; is properly forwarded to the immediately following instruction
; (M-stage forward: mul result in M, consumer in E, no NOP needed).
;
; Expected signature: 84
;   x5 = 6, x6 = 7
;   x7 = mul(x5, x6) = 42
;   x8 = add(x7, x7) = 84  <- forward from M stage, no bubble

main:
        addi x5, x0, 6          # x5 = 6
        addi x6, x0, 7          # x6 = 7
        mul  x7, x5, x6          # x7 = 42  (6 * 7, single-cycle)
        add  x8, x7, x7          # x8 = 84  (forward x7 from M stage, no NOP)
        sw   x8, 100(x0)         # mem[100] = 84 (final signature)
        beq  x0, x0, done
done:
        beq  x0, x0, done
