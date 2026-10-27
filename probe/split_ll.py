import re, sys, subprocess, os

path = sys.argv[1]
outdir = sys.argv[2]
os.makedirs(outdir, exist_ok=True)
text = open(path).read()
lines = text.split("\n")

# split into top-level segments: each `define ... {` ... `}` block is one unit;
# everything else goes into the shared header.
header = []
funcs = []
i = 0
while i < len(lines):
    ln = lines[i]
    if ln.startswith("define "):
        block = [ln]
        i += 1
        while i < len(lines) and lines[i] != "}":
            block.append(lines[i])
            i += 1
        if i < len(lines):
            block.append("}")
            i += 1
        funcs.append(block)
    else:
        header.append(ln)
        i += 1

name_re = re.compile(r"@([\w.$]+)")
for idx, block in enumerate(funcs):
    m = name_re.search(block[0])
    name = m.group(1) if m else f"f{idx}"
    p = os.path.join(outdir, f"{idx:02d}_{name}.ll")
    with open(p, "w") as f:
        f.write("\n".join(header + block) + "\n")
    r = subprocess.run(["../driver", "ir", p, p + ".sa"], capture_output=True, text=True)
    status = "OK" if r.returncode == 0 else (r.stderr.strip().split("\n")[-1] if r.stderr.strip() else f"rc={r.returncode}")
    size = os.path.getsize(p + ".sa") if r.returncode == 0 else 0
    print(f"{name}: {status} sa_bytes={size}")
print(f"total funcs: {len(funcs)}")
