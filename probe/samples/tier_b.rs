// Tier (b): Vec/String core+alloc usage. Translated unit = rlib IR;
// native truth = same file compiled as bin.
#[no_mangle]
pub extern "C" fn vec_sum(n: u32) -> u64 {
    let mut v: Vec<u64> = Vec::new();
    let mut i: u64 = 0;
    while i < n as u64 {
        v.push(i * i);
        i += 1;
    }
    let mut s: u64 = 0;
    for x in &v {
        s += x;
    }
    s
}

#[no_mangle]
pub extern "C" fn vec_filter_sum(n: u32) -> u64 {
    let v: Vec<u64> = (0..n as u64).collect();
    v.iter().filter(|x| **x % 2 == 0).map(|x| x + 1).sum()
}

#[no_mangle]
pub extern "C" fn string_build() -> u64 {
    let mut s = String::from("ab");
    s.push_str("cd");
    let mut i = 0;
    while i < 3 {
        s.push('x');
        i += 1;
    }
    let mut sum: u64 = 0;
    for b in s.as_bytes() {
        sum += *b as u64;
    }
    s.len() as u64 * 1000 + sum
}

#[no_mangle]
pub extern "C" fn string_fmt() -> u64 {
    let s = format!("{}:{}", 40, 2);
    let mut sum: u64 = 0;
    for b in s.as_bytes() {
        sum += *b as u64;
    }
    s.len() as u64 * 1000 + sum
}

#[no_mangle]
pub extern "C" fn string_split_count() -> u64 {
    let text = "alpha,beta,,gamma,delta";
    let parts: Vec<&str> = text.split(',').collect();
    let mut total: u64 = 0;
    for p in &parts {
        total += p.len() as u64;
    }
    parts.len() as u64 * 100 + total
}

fn main() {
    println!("vec_sum(10) = {}", vec_sum(10));
    println!("vec_filter_sum(10) = {}", vec_filter_sum(10));
    println!("string_build() = {}", string_build());
    println!("string_fmt() = {}", string_fmt());
    println!("string_split_count() = {}", string_split_count());
}
