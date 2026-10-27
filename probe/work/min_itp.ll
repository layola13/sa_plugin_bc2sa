define void @itp(ptr %p) {
entry:
  store ptr inttoptr (i64 8 to ptr), ptr %p, align 8
  ret void
}
