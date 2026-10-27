declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
define i64 @ev(i64 %a, i64 %b) {
entry:
  %r = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %a, i64 %b)
  %v = extractvalue { i64, i1 } %r, 0
  ret i64 %v
}
