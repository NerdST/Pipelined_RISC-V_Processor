; T26: JALR - indirect call and return
; Load the absolute address of 'func' (PC=20) into x5, call it with jalr.
; func puts 7 in x10 and returns via jalr x0, 0(x1) (ret).
; Expected signature: 7 at address 100
;
; Memory layout:
;   PC= 0: addi x5, x0, 20        (load func address)
;   PC= 4: jalr x1, 0(x5)         (call func; x1 = 8 = return addr)
;   PC= 8: sw   x10, 100(x0)      (store result after return)
;   PC=12: beq  x0, x0, done
;   PC=16: beq  x0, x0, done      (done loop)
;   PC=20: addi x10, x0, 7        (func: set return value)
;   PC=24: jalr x0, 0(x1)         (ret: jump back to x1=8)

main:
        addi x5,  x0,  20          # x5 = byte address of func
        jalr x1,  0(x5)            # call func; x1 = PC+4 = 8
        sw   x10, 100(x0)          # [PC=8] mem[100] = x10 (result from func)
        beq  x0,  x0, done

done:
        beq  x0,  x0, done         # PC=16 - infinite loop

func:                               # PC=20
        addi x10, x0, 7            # return value = 7
        ret                        # jalr x0, 0(x1) -- return to caller
