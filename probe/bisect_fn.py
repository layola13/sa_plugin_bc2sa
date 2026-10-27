#!/usr/bin/env python3
"""Find the first translator-blocking instruction in a single-function .ll.
Usage: bisect_fn.py <file.ll> <driver>
Strategy: emit prefixes of the function body (whole blocks, then single
instructions), closing the tail block with a synthetic ret. The first prefix
that fails contains the blocking instruction at its tail."""
import re, subprocess, sys

path, driver = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
hdr, body, ret_ty = [], [], "i64"
in_fn = False
for ln in lines:
    if ln.startswith("define "):
        in_fn = True
        m = re.search(r"define\s+(?:\S+\s+)*?(\w+|%?\w+|void|\{[^}]*\}|<[^>]*>)\s+@", ln)
        # crude ret-type grab: token before @name
        m2 = re.search(r"@([\w.$]+)\(", ln)
        pre = ln[: m2.start()].split()
        ret_ty = pre[-1] if pre else "void"
        body.append(ln)
        continue
    if in_fn:
        body.append(ln)
        if ln == "}":
            in_fn = False
    else:
        hdr.append(ln)

# blocks: split body[1:-1] at label lines
inner = body[1:-1]
blocks, cur = [], []
for ln in inner:
    if re.match(r"^[\w.$][\w.$-]*:\s*(;.*)?$", ln) and cur:
        blocks.append(cur)
        cur = [ln]
    else:
        cur.append(ln)
if cur:
    blocks.append(cur)

ret_stmt = "  ret void" if ret_ty == "void" else f"  ret {ret_ty} 0"

def run(block_list, tail_extra=None):
    out = list(hdr)
    out.append(body[0])
    for b in block_list[:-1]:
        out.extend(b)
    last = list(block_list[-1])
    # drop terminator of last block, drop phis in last block
    last = [l for l in last if not re.match(r"^\s*(br |ret |switch |unreachable)", l)]
    last = [l for l in last if "= phi " not in l]
    if tail_extra:
        last.extend(tail_extra)
    last.append(ret_stmt)
    out.extend(last)
    out.append("}")
    p = "/tmp/bisect_probe.ll"
    open(p, "w").write("\n".join(out) + "\n")
    r = subprocess.run([driver, "ir", p, p + ".sa"], capture_output=True, text=True)
    return r.returncode == 0

# block-level bisect
bad_block = None
for k in range(1, len(blocks) + 1):
    if not run(blocks[:k]):
        bad_block = k - 1
        break
if bad_block is None:
    print("ALL BLOCKS PASS (blocker is interaction/terminator?)")
    sys.exit(0)
print(f"first failing block index {bad_block}:")
blk = blocks[bad_block]
for l in blk:
    print("   ", l)
# instruction-level: prefix within the bad block (only works if it is the first block or values are local)
base = blocks[:bad_block]
insts = [l for l in blk[1:] if l.strip() and not l.strip().startswith(";")]
label = blk[0]
for k in range(0, len(insts) + 1):
    trial = base + [[label] + insts[:k]]
    if not run(trial):
        print(f"first failing instruction at offset {k}: {insts[k-1] if k>0 else '(block open)'}")
        break
