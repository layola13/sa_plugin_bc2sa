// Tier (c) wrapper (Agent AM): the real crate function under test is
// fnv 1.0.7's FnvHasher (crates.io crate `fnv`, version 1.0.7;
// .crate sha256 3f9eec918d3f24069decb9af1554cad7c880e2da24a9afd88aca000531ab82c1),
// vendored at src/fnv.rs. Vendoring adaptations (mechanical only):
//   * the file sits at the crate root in the original (lib.rs); included
//     here as a module instead (its `#![cfg_attr(..., no_std)]` line is
//     kept and applies to the module);
//   * the 40-line crate-level doc cfg_attr block (original lines 24-63,
//     documentation only) was removed; all code is byte-identical;
//   * compiled without cargo feature "std", i.e. fnv's own supported
//     no_std configuration (std-gated HashMap/HashSet aliases compile out).
pub mod fnv;

use core::hash::Hasher;
use fnv::FnvHasher;

#[no_mangle]
pub extern "C" fn fnv1a_fixed() -> u64 {
    let mut h = FnvHasher::default();
    h.write(b"hello bc2sa: real crate fnv");
    h.write_u32(0xdead_beef);
    h.write_usize(123_456_789);
    h.finish()
}

#[no_mangle]
pub extern "C" fn fnv1a_stream(n: u32) -> u64 {
    let mut h = FnvHasher::default();
    let mut buf = [0u8; 64];
    let mut i: u32 = 0;
    while i < n {
        let mut j: usize = 0;
        while j < 64 {
            buf[j] = ((i * 31 + j as u32 * 7 + 13) % 251) as u8;
            j += 1;
        }
        h.write(&buf);
        i += 1;
    }
    h.finish()
}
