declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
define i64 @sc(i64 %a, i64 %b) {
entry:
  %r = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %a, i64 %b)
  ret i64 0
}
