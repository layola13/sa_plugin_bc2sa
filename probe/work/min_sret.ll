define i64 @sretuse(i64 %a) {
entry:
  %s = alloca [24 x i8], align 8
  call void @callee(ptr sret([24 x i8]) align 8 %s, i64 %a)
  ret i64 %a
}
declare void @callee(ptr, i64)
