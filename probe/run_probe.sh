#!/usr/bin/env bash
# bc2sa probe reproduction (Agent AM, 2026-10-27). Run from the repo root on
# the Colab box. Assumes: zig 0.17 at /opt/zig17, sa at
# /content/sa_all/sci/zig-out/bin, SA_STD_DIR=/content/sa_all/sci/sa_std,
# rustc on PATH (rustup stable; the probe used 1.99.1 / LLVM 23.1.1).
# Every step is timeout-bounded; heavy steps are serial by design.
set -u
cd "$(dirname "$0")/.." || exit 1
export PATH="$HOME/.cargo/bin:/content/sa_all/sci/zig-out/bin:/content/sa_all/sa_plugin_sla/zig-out/bin:$PATH"
export SA_PLUGIN_DEV=1 SLA_NO_FRESHNESS_CACHE=1 SA_STD_DIR=/content/sa_all/sci/sa_std
W=probe/work
mkdir -p "$W"

echo "== versions"; rustc --version --verbose | grep -E "release:|LLVM"
llvm-dis-14 --version | head -1; llvm-dis-20 --version | head -1

echo "== build driver"
timeout 120 /opt/zig17/zig build-exe --dep bc2sa -Mroot=probe/driver.zig -Mbc2sa=src/llvm2sa.zig -femit-bin=probe/driver || exit 1

echo "== step 0: bitcode wall (expected: both dis fail, driver bc fails)"
printf 'pub fn add(a: i32, b: i32) -> i32 { a + b }\n' > "$W/t0.rs"
rustc --emit=llvm-bc -C panic=abort -C opt-level=2 --crate-type rlib "$W/t0.rs" -o "$W/t0.bc"
llvm-dis-14 -o /dev/null "$W/t0.bc" 2>&1 | head -1
llvm-dis-20 -o /dev/null "$W/t0.bc" 2>&1 | head -1
./probe/driver bc "$W/t0.bc" "$W/t0.sa" 2>&1 | head -1

FLAGS="--edition 2021 -C panic=abort -C opt-level=2"
NVFLAGS="-C llvm-args=-vectorize-loops=false -C llvm-args=-vectorize-slp=false"

echo "== tier (a)"
rustc $FLAGS --emit=llvm-ir,llvm-bc --crate-type rlib probe/samples/tier_a.rs -o "$W/tier_a"
rustc $FLAGS probe/samples/tier_a.rs -o "$W/tier_a_native"
"$W/tier_a_native" > "$W/tier_a_truth.txt"
python3 probe/normalize_ll.py "$W/tier_a.ll" "$W/tier_a_norm.ll"
./probe/driver ir "$W/tier_a_norm.ll" "$W/tier_a.sa"
timeout 60 sa build-exe "$W/harness_a_nofib.sla" && timeout 10 "$W/harness_a_nofib"

echo "== tier (b) (de-vectorized)"
rustc $FLAGS --emit=llvm-ir,llvm-bc --crate-type rlib probe/samples/tier_b.rs -o "$W/tier_b"
rustc $FLAGS probe/samples/tier_b.rs -o "$W/tier_b_native"
"$W/tier_b_native" > "$W/tier_b_truth.txt"
rustc $FLAGS $NVFLAGS --emit=llvm-ir --crate-type rlib probe/samples/tier_b.rs -o "$W/tier_b_nv"
python3 probe/normalize_ll.py "$W/tier_b_nv" "$W/tier_b_nv_norm.ll"
python3 probe/split_ll.py "$W/tier_b_nv_norm.ll" "$W/tier_b_nv_split"
timeout 60 sa build-exe "$W/harness_b.sla" && timeout 10 "$W/harness_b"

echo "== tier (c) fnv 1.0.7"
rustc $FLAGS --emit=llvm-ir,llvm-bc --crate-type rlib probe/tier_c/src/lib.rs -o "$W/tier_c"
rustc $FLAGS probe/tier_c/truth.rs -o "$W/tier_c_native"
"$W/tier_c_native" > "$W/tier_c_truth.txt"
rustc $FLAGS $NVFLAGS --emit=llvm-ir --crate-type rlib probe/tier_c/src/lib.rs -o "$W/tier_c_nv"
./probe/driver ir "$W/tier_c_nv" "$W/tier_c_nv.sa"
timeout 60 sa build-exe "$W/harness_c_fixed.sla" && timeout 10 "$W/harness_c_fixed"
echo "== done (see probe/REPORT.md for adjudications)"
