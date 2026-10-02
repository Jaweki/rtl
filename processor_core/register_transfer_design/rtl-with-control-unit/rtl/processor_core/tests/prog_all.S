# Exercises every RV32I instruction the core implements.
        addi x1, x0, 5          # x1 = 5
        addi x2, x0, -3         # x2 = -3
        add  x3, x1, x2         # 2
        sub  x4, x1, x2         # 8
        sll  x5, x1, x1         # 5<<5 = 160
        slt  x6, x2, x1         # 1  (signed -3 < 5)
        sltu x7, x2, x1         # 0  (unsigned 0xFFFFFFFD > 5)
        xor  x8, x1, x2
        srl  x9, x2, x1         # logical shift of -3
        sra  x10, x2, x1        # arithmetic shift of -3 -> -1
        or   x11, x1, x2
        and  x12, x1, x2
        slti x13, x2, 0         # 1
        sltiu x14, x1, 10       # 1
        xori x15, x1, 15
        ori  x16, x1, 0x70
        andi x17, x16, 0x7f
        slli x18, x1, 4         # 80
        srli x19, x2, 28        # 0xF
        srai x20, x2, 1         # -2
        lui  x21, 0x12345       # 0x12345000
        auipc x22, 1            # PC + 0x1000
        # ---- memory ----
        addi x23, x0, 256       # base address
        lui  x24, 0xDEADC       # 0xDEADC000
        addi x24, x24, -273     # 0xDEADBEEF
        sw   x24, 0(x23)
        lw   x25, 0(x23)        # 0xDEADBEEF
        lb   x26, 0(x23)        # 0xFFFFFFEF (sign-extended)
        lbu  x27, 0(x23)        # 0xEF
        lh   x28, 2(x23)        # 0xFFFFDEAD
        lhu  x29, 2(x23)        # 0xDEAD
        sb   x1, 8(x23)
        sh   x2, 10(x23)
        lw   x30, 8(x23)        # 0xFFFD0005
        # ---- branches (each taken branch skips a poison write) ----
        addi x31, x0, 0
        beq  x1, x1, b1
        addi x31, x31, 100      # skipped
b1:     bne  x1, x2, b2
        addi x31, x31, 100      # skipped
b2:     blt  x2, x1, b3
        addi x31, x31, 100      # skipped
b3:     bge  x1, x2, b4
        addi x31, x31, 100      # skipped
b4:     bltu x1, x2, b5
        addi x31, x31, 100      # skipped
b5:     bgeu x2, x1, b6
        addi x31, x31, 100      # skipped
b6:     beq  x1, x2, bad        # not taken
        addi x31, x31, 1        # executed once -> x31 = 1
        # ---- jumps ----
        jal  x1, sub1           # x1 = return address
        addi x31, x31, 10       # executed after return -> 11
        j done
sub1:   addi x31, x31, 20       # 21 then 31
        jalr x0, 0(x1)          # return
bad:    addi x31, x0, -1
done:   j done                  # spin forever
