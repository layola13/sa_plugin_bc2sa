define i32 @sw(i32 %x) {
entry:
  switch i32 %x, label %d [
    i32 0, label %a
    i32 1, label %b
  ]
a:
  ret i32 10
b:
  ret i32 20
d:
  ret i32 30
}
