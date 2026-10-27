#!/usr/bin/env python3
"""Probe normalizer (Agent AM): rewrites LLVM-23-printer textual IR into the
dialect the bc2sa translator (LLVM <=17 era) accepts. Three measured fixes:
  1. `icmp samesign <pred>`      -> `icmp <pred>`        (samesign flag, LLVM 18+)
  2. trailing instruction metadata `, !llvm.loop !N` (and generic `, !x.y !N`)
     at end of instruction lines -> stripped
  3. hex float literals `f0x<16 hex>` (double bits) / `f0x<8 hex>` (float bits)
     -> decimal repr
Usage: normalize_ll.py <in.ll> <out.ll> ; prints per-fix counts.
"""
import re, struct, sys

src = open(sys.argv[1]).read()
counts = {"samesign": 0, "meta_suffix": 0, "hexfloat": 0, "noalias_scope_decl": 0}

src, n = re.subn(r"\bicmp samesign ", "icmp ", src)
counts["samesign"] = n

def strip_meta(line):
    # only instruction lines (indented) get suffix stripping; loop to
    # fixpoint: LLVM prints stacked suffixes (`!noalias !14, !nonnull !10`)
    if line.startswith(" ") or line.startswith("\t"):
        while True:
            new, n = re.subn(r", ![a-zA-Z_][\w.]* !\d+\s*$", "", line)
            counts["meta_suffix"] += n
            if n == 0:
                return line
            line = new
    return line

src = "\n".join(strip_meta(ln) for ln in src.split("\n"))

def hexfloat(m):
    digits = m.group(1)
    counts["hexfloat"] += 1
    if len(digits) == 16:
        v = struct.unpack(">d", bytes.fromhex(digits))[0]
    elif len(digits) == 8:
        v = struct.unpack(">f", bytes.fromhex(digits))[0]
    else:
        return m.group(0)
    return repr(v)

src = re.sub(r"f0x([0-9A-Fa-f]+)", hexfloat, src)

# 4. llvm.experimental.noalias.scope.decl: declare uses the `metadata` type the
#    translator cannot parse; call sites pass metadata args. Annotation-only:
#    drop both lines.
kept = []
n_drop = 0
for ln in src.split("\n"):
    if "llvm.experimental.noalias.scope.decl" in ln:
        n_drop += 1
        continue
    kept.append(ln)
src = "\n".join(kept)
counts["noalias_scope_decl"] = n_drop

open(sys.argv[2], "w").write(src)
print("FIXES", counts)
