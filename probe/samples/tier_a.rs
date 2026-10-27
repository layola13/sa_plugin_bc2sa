// Tier (a): pure functions + struct/enum/match, no alloc, no IO in the
// translated unit. Compiled as rlib for translation; as bin for native truth.
enum Shape {
    Circle(f64),
    Rect(f64, f64),
    Unit,
}

struct Pt {
    x: i64,
    y: i64,
}

fn shape_of(tag: u32, a: f64, b: f64) -> Shape {
    match tag {
        0 => Shape::Circle(a),
        1 => Shape::Rect(a, b),
        _ => Shape::Unit,
    }
}

#[no_mangle]
pub extern "C" fn area_code(tag: u32, a: f64, b: f64) -> f64 {
    let s = shape_of(tag, a, b);
    match s {
        Shape::Circle(r) => 3.141592653589793 * r * r,
        Shape::Rect(w, h) => w * h,
        Shape::Unit => -1.0,
    }
}

#[no_mangle]
pub extern "C" fn classify(n: i32) -> i32 {
    match n {
        i32::MIN..=-100 => -3,
        -99..=-1 => -1,
        0 => 0,
        1..=99 => 1,
        100..=999 => 2,
        _ => 3,
    }
}

#[no_mangle]
pub extern "C" fn fib(n: u32) -> u64 {
    let mut a: u64 = 0;
    let mut b: u64 = 1;
    let mut i: u32 = 0;
    while i < n {
        let t = a + b;
        a = b;
        b = t;
        i += 1;
    }
    a
}

#[no_mangle]
pub extern "C" fn dist2(x1: i64, y1: i64, x2: i64, y2: i64) -> i64 {
    let p = Pt { x: x2 - x1, y: y2 - y1 };
    p.x * p.x + p.y * p.y
}

#[no_mangle]
pub extern "C" fn sign_chain(x: i32) -> i32 {
    if x > 10 {
        2
    } else if x > 0 {
        1
    } else if x == 0 {
        0
    } else if x > -10 {
        -1
    } else {
        -2
    }
}

fn main() {
    println!("area_code(0, 2.0, 0.0) = {:.4}", area_code(0, 2.0, 0.0));
    println!("area_code(1, 3.0, 4.0) = {:.4}", area_code(1, 3.0, 4.0));
    println!("area_code(7, 3.0, 4.0) = {:.4}", area_code(7, 3.0, 4.0));
    println!("classify(-100) = {}", classify(-100));
    println!("classify(-5) = {}", classify(-5));
    println!("classify(0) = {}", classify(0));
    println!("classify(42) = {}", classify(42));
    println!("classify(500) = {}", classify(500));
    println!("classify(5000) = {}", classify(5000));
    println!("fib(20) = {}", fib(20));
    println!("dist2(0, 0, 3, 4) = {}", dist2(0, 0, 3, 4));
    println!("sign_chain(20) = {}", sign_chain(20));
    println!("sign_chain(-20) = {}", sign_chain(-20));
    println!("sign_chain(0) = {}", sign_chain(0));
}
