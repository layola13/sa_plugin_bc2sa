// Tier (c) native-truth binary (Agent AM): same wrapper computations as
// src/lib.rs, printing reference values from the natively compiled crate.
#[path = "src/fnv.rs"]
mod fnv;

use std::hash::Hasher;
use fnv::FnvHasher;

fn fnv1a_fixed() -> u64 {
    let mut h = FnvHasher::default();
    h.write(b"hello bc2sa: real crate fnv");
    h.write_u32(0xdead_beef);
    h.write_usize(123_456_789);
    h.finish()
}

fn fnv1a_stream(n: u32) -> u64 {
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

fn main() {
    println!("fnv1a_fixed() = {}", fnv1a_fixed());
    println!("fnv1a_stream(100) = {}", fnv1a_stream(100));
    println!("fnv1a_stream(1) = {}", fnv1a_stream(1));
}
