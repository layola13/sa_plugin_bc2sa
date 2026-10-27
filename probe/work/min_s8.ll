define void @s8(ptr %p) {
entry:
  store i8 65, ptr %p, align 1
  ret void
}
