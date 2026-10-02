#!/usr/bin/env python3
"""Tiny RV32I assembler + reference simulator (for testing the Verilog core).

usage: python3 asm.py prog.S prog.hex expected_regs.hex [steps]
  prog.hex          one 32-bit word per line (for $readmemh)
  expected_regs.hex x0..x31 after running `steps` instructions in the Python model
"""
import sys, re

ABI = {'zero':0,'ra':1,'sp':2,'gp':3,'tp':4,'t0':5,'t1':6,'t2':7,'s0':8,'fp':8,'s1':9,
       'a0':10,'a1':11,'a2':12,'a3':13,'a4':14,'a5':15,'a6':16,'a7':17,
       's2':18,'s3':19,'s4':20,'s5':21,'s6':22,'s7':23,'s8':24,'s9':25,'s10':26,'s11':27,
       't3':28,'t4':29,'t5':30,'t6':31}
def reg(s):
    s = s.strip()
    if s in ABI: return ABI[s]
    m = re.fullmatch(r'x(\d+)', s)
    if m and int(m.group(1)) < 32: return int(m.group(1))
    raise ValueError('bad register ' + s)

R  = {'add':(0,0),'sub':(0,0x20),'sll':(1,0),'slt':(2,0),'sltu':(3,0),'xor':(4,0),
      'srl':(5,0),'sra':(5,0x20),'or':(6,0),'and':(7,0)}
I  = {'addi':0,'slti':2,'sltiu':3,'xori':4,'ori':6,'andi':7}
SH = {'slli':(1,0),'srli':(5,0),'srai':(5,0x20)}
LD = {'lb':0,'lh':1,'lw':2,'lbu':4,'lhu':5}
ST = {'sb':0,'sh':1,'sw':2}
BR = {'beq':0,'bne':1,'blt':4,'bge':5,'bltu':6,'bgeu':7}

def enc_r(f7,rs2,rs1,f3,rd,op): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_i(imm,rs1,f3,rd,op): return ((imm&0xfff)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_s(imm,rs2,rs1,f3,op):
    imm &= 0xfff
    return ((imm>>5)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1f)<<7)|op
def enc_b(imm,rs2,rs1,f3,op):
    imm &= 0x1fff
    return (((imm>>12)&1)<<31)|(((imm>>5)&0x3f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&0xf)<<8)|(((imm>>11)&1)<<7)|op
def enc_u(imm,rd,op): return ((imm&0xfffff)<<12)|(rd<<7)|op
def enc_j(imm,rd,op):
    imm &= 0x1fffff
    return (((imm>>20)&1)<<31)|(((imm>>1)&0x3ff)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&0xff)<<12)|(rd<<7)|op

def parse_mem(s):
    m = re.fullmatch(r'\s*(-?\w+)\((\w+)\)\s*', s)
    return int(m.group(1), 0), reg(m.group(2))

def assemble(src):
    lines, labels = [], {}
    for raw in src.splitlines():
        t = raw.split('#')[0].strip()
        if not t: continue
        while ':' in t:
            lab, t = t.split(':', 1); labels[lab.strip()] = len(lines) * 4; t = t.strip()
        if t: lines.append(t)
    words = []
    for n, t in enumerate(lines):
        pc = n * 4
        op, _, rest = t.partition(' ')
        a = [x.strip() for x in rest.split(',')] if rest.strip() else []
        def tgt(x): return (labels[x] - pc) if x in labels else int(x, 0)
        if op in R:
            f3,f7 = R[op]; w = enc_r(f7,reg(a[2]),reg(a[1]),f3,reg(a[0]),0x33)
        elif op in I:
            w = enc_i(int(a[2],0),reg(a[1]),I[op],reg(a[0]),0x13)
        elif op in SH:
            f3,f7 = SH[op]; w = enc_i((f7<<5)|(int(a[2],0)&31),reg(a[1]),f3,reg(a[0]),0x13)
        elif op in LD:
            off,rb = parse_mem(a[1]); w = enc_i(off,rb,LD[op],reg(a[0]),0x03)
        elif op in ST:
            off,rb = parse_mem(a[1]); w = enc_s(off,reg(a[0]),rb,ST[op],0x23)
        elif op in BR:
            w = enc_b(tgt(a[2]),reg(a[1]),reg(a[0]),BR[op],0x63)
        elif op == 'jal':   w = enc_j(tgt(a[1]),reg(a[0]),0x6f)
        elif op == 'jalr':
            off,rb = parse_mem(a[1]); w = enc_i(off,rb,0,reg(a[0]),0x67)
        elif op == 'lui':   w = enc_u(int(a[1],0),reg(a[0]),0x37)
        elif op == 'auipc': w = enc_u(int(a[1],0),reg(a[0]),0x17)
        elif op == 'nop':   w = 0x00000013
        elif op == 'li':    w = enc_i(int(a[1],0),0,0,reg(a[0]),0x13)   # small immediates only
        elif op == 'mv':    w = enc_i(0,reg(a[1]),0,reg(a[0]),0x13)
        elif op == 'j':     w = enc_j(tgt(a[0]),0,0x6f)
        else: raise ValueError('unknown instruction: ' + t)
        words.append(w & 0xffffffff)
    return words

# ---------------- independent reference model ----------------
def sx(v, bits): v &= (1<<bits)-1; return v - (1<<bits) if v >> (bits-1) else v
def run(words, steps):
    M = 0xffffffff; x = [0]*32; mem = {}; pc = 0
    def rd8(a): return mem.get(a & M, 0)
    for _ in range(steps):
        i = words[(pc >> 2) % len(words)] if (pc >> 2) < len(words) else 0x13
        op=i&0x7f; rd=(i>>7)&31; f3=(i>>12)&7; r1=(i>>15)&31; r2=(i>>20)&31; f7=i>>25
        a,b = x[r1], x[r2]; npc = (pc+4) & M; wr = None
        immI = sx(i>>20,12); immS = sx(((i>>25)<<5)|((i>>7)&31),12)
        immB = sx((((i>>31)&1)<<12)|(((i>>7)&1)<<11)|(((i>>25)&0x3f)<<5)|(((i>>8)&0xf)<<1),13)
        immU = i & 0xfffff000
        immJ = sx((((i>>31)&1)<<20)|(((i>>12)&0xff)<<12)|(((i>>20)&1)<<11)|(((i>>21)&0x3ff)<<1),21)
        def alu(f3,a,b,sub_sra):
            if f3==0: return (a-b)&M if sub_sra else (a+b)&M
            if f3==1: return (a<<(b&31))&M
            if f3==2: return int(sx(a,32) < sx(b,32))
            if f3==3: return int(a < b)
            if f3==4: return a^b
            if f3==5: return (sx(a,32)>>(b&31))&M if sub_sra else a>>(b&31)
            if f3==6: return a|b
            return a&b
        if op==0x33: wr = alu(f3,a,b,f7==0x20)
        elif op==0x13: wr = alu(f3,a,immI&M,(f3==5 and (i>>30)&1))
        elif op==0x03:
            ad=(a+immI)&M; n={0:1,1:2,2:4,4:1,5:2}[f3]
            v=sum(rd8(ad+k)<<(8*k) for k in range(n))
            wr = (sx(v,8*n)&M) if f3 in (0,1,2) else v
        elif op==0x23:
            ad=(a+immS)&M; n={0:1,1:2,2:4}[f3]
            for k in range(n): mem[(ad+k)&M]=(b>>(8*k))&0xff
        elif op==0x63:
            t={0:a==b,1:a!=b,4:sx(a,32)<sx(b,32),5:sx(a,32)>=sx(b,32),6:a<b,7:a>=b}[f3]
            if t: npc=(pc+immB)&M
        elif op==0x6f: wr=(pc+4)&M; npc=(pc+immJ)&M
        elif op==0x67: wr=(pc+4)&M; npc=((a+immI)&M)&~1
        elif op==0x37: wr=immU
        elif op==0x17: wr=(pc+immU)&M
        if wr is not None and rd!=0: x[rd]=wr&M
        pc=npc
    return x, mem

if __name__ == '__main__':
    src = open(sys.argv[1]).read(); steps = int(sys.argv[4]) if len(sys.argv) > 4 else 500
    w = assemble(src)
    open(sys.argv[2],'w').write(''.join('%08x\n' % v for v in w))
    x,_ = run(w, steps)
    open(sys.argv[3],'w').write(''.join('%08x\n' % v for v in x))
    print('assembled %d instructions' % len(w))
