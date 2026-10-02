#!/usr/bin/env python3
"""
gen_waveforms.py : run every component testbench and draw its waveform as a PNG.

Usage (from processor_core/docs/):   python3 gen_waveforms.py
Needs : iverilog, vvp, python3, matplotlib
Output: docs/waveforms/<module>.png   (the same signals you would add in GTKWave)
"""
import os, subprocess, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "components")
OUT  = os.path.join(HERE, "waveforms")

# (folder, source, testbench, vcd, signals to show, time window in ns)
JOBS = [
 ("alu", "alu", "alu-tb", "alu.vcd", ["a", "b", "alu_op", "result", "zero"], (0, 160)),
 ("comparator", "comparator", "comparator-tb", "comparator.vcd", ["a", "b", "funct3", "eq", "lt", "ltu", "taken"], (0, 100)),
 ("program_counter", "program-counter", "program-counter-tb", "program_counter.vcd", ["clk", "rst", "en", "next_pc", "pc", "pc_plus4"], (0, 100)),
 ("registers", "register", "register-tb", "register.vcd", ["clk", "rst", "en", "d", "q"], (0, 70)),
 ("register_files", "register-file", "register-file-tb", "register_file.vcd", ["clk", "we", "rd_addr", "rd_data", "rs1_addr", "rs2_addr", "rs1_data", "rs2_data"], (0, 90)),
 ("immediate_generator", "immediate-generator", "immediate-generator-tb", "immediate_generator.vcd", ["instr", "imm"], (0, 90)),
 ("memory_devices", "instruction-memory", "instruction-memory-tb", "instruction_memory.vcd", ["addr", "instr"], (0, 50)),
 ("memory_devices", "data-memory", "data-memory-tb", "data_memory.vcd", ["clk", "mem_write", "mem_read", "funct3", "addr", "wdata", "rdata"], (0, 130)),
]

def parse_vcd(path):
    toks = open(path).read().split()
    scale_ns, ids, changes = 1.0, {}, {}
    scope, i, in_defs, t = [], 0, True, 0.0
    while i < len(toks):
        k = toks[i]
        if in_defs:
            if k == "$timescale":
                j = toks.index("$end", i); ts = "".join(toks[i+1:j]).lower()
                num = int("".join(c for c in ts if c.isdigit())); unit = ts.lstrip("0123456789")
                scale_ns = num * {"s": 1e9, "ms": 1e6, "us": 1e3, "ns": 1, "ps": 1e-3, "fs": 1e-6}[unit]
                i = j
            elif k == "$scope": scope.append(toks[i+2])
            elif k == "$upscope": scope.pop()
            elif k == "$var":
                width, vid, name = int(toks[i+2]), toks[i+3], toks[i+4]
                if len(scope) == 1:                       # testbench-level signals only
                    ids[vid] = (name, width); changes[vid] = []
            elif k == "$enddefinitions":
                in_defs = False; i = toks.index("$end", i)
            i += 1; continue
        if k.startswith("#"): t = int(k[1:]) * scale_ns
        elif k[0] in "bB":
            vid = toks[i+1]; i += 1
            if vid in changes:
                bits = k[1:]; changes[vid].append((t, None if set(bits.lower()) & set("xz") else int(bits, 2)))
        elif k[0] in "01xXzZ" and not k.startswith("$"):
            vid = k[1:]
            if vid in changes:
                changes[vid].append((t, None if k[0] in "xXzZ" else int(k[0])))
        i += 1
    return {n: (w, changes[v]) for v, (n, w) in ids.items()}

def draw(sigs, names, window, title, out):
    t0, t1 = window
    fig, ax = plt.subplots(figsize=(11, 0.62 * len(names) + 1.1), dpi=140)
    n = len(names)
    for r, name in enumerate(names):
        w, ch = sigs[name]; y = n - 1 - r
        ch = sorted(ch, key=lambda c: c[0])
        # collapse to segments
        segs = []
        for k, (t, v) in enumerate(ch):
            te = ch[k+1][0] if k + 1 < len(ch) else t1
            if te > t and (not segs or segs[-1][2] != v):
                segs.append([t, te, v])
            elif segs and segs[-1][2] == v:
                segs[-1][1] = te
        if w == 1:
            xs, ys = [], []
            for a, b, v in segs:
                val = 0.5 if v is None else v
                xs += [a, b]; ys += [y + 0.1 + 0.7 * val] * 2
            ax.step(xs, ys, where="post", color="#1d4ed8", lw=1.6)
            ax.plot(xs, ys, color="#1d4ed8", lw=1.6)
        else:
            for a, b, v in segs:
                a2, b2 = max(a, t0), min(b, t1)
                if b2 <= a2: continue
                bad = v is None; e = 0.35
                pts = [(a2, y+.45), (a2+e, y+.8), (b2-e, y+.8), (b2, y+.45), (b2-e, y+.1), (a2+e, y+.1)] if (b2-a2) > 2*e else \
                      [(a2, y+.1), (b2, y+.1), (b2, y+.8), (a2, y+.8)]
                ax.add_patch(Polygon(pts, closed=True, fc="#fecaca" if bad else "#dbeafe", ec="#b91c1c" if bad else "#1d4ed8", lw=1.0))
                if bad: txt = "x"
                elif w <= 4: txt = format(v, "0%db" % w)
                else: txt = format(v, "0%dX" % ((w + 3) // 4))
                if (b2 - a2) * (9.6 / (t1 - t0)) > 0.055 * len(txt) + 0.06:
                    ax.text((a2 + b2) / 2, y + .45, txt, ha="center", va="center", fontsize=6.5, family="monospace")
    ax.set_yticks([n - 1 - r + .45 for r in range(n)]); ax.set_yticklabels(names, family="monospace", fontsize=8)
    ax.set_xlim(t0, t1); ax.set_ylim(-0.1, n)
    span = t1 - t0; step = 1 if span <= 12 else 2 if span <= 30 else 5 if span <= 60 else 10 if span <= 200 else 20
    ticks = list(range(int(t0), int(t1) + 1, step))
    ax.set_xticks(ticks); ax.set_xlabel("time (ns)"); ax.grid(axis="x", color="#d1d5db", lw=.6, ls=":")
    ax.set_title(title, fontsize=10, loc="left")
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    fig.tight_layout(); fig.savefig(out); plt.close(fig)

def main():
    os.makedirs(OUT, exist_ok=True)
    for folder, src, tb, vcd, names, win in JOBS:
        d = os.path.join(ROOT, folder)
        exe = os.path.join(d, src + ".out")
        subprocess.run(["iverilog", "-g2005", "-o", exe, src + ".v", tb + ".v"], cwd=d, check=True)
        subprocess.run(["vvp", exe], cwd=d, check=True, stdout=subprocess.DEVNULL)
        sigs = parse_vcd(os.path.join(d, vcd))
        png = os.path.join(OUT, vcd.replace(".vcd", ".png"))
        tmax = max(t for _, ch in sigs.values() for t, _ in ch)
        win = (win[0], min(win[1], tmax + 2))          # stop where the simulation stops
        draw(sigs, names, win, vcd.replace(".vcd", "") + "  (from " + tb + ".v)", png)
        print("wrote", os.path.relpath(png, HERE))

if __name__ == "__main__":
    main()
