define void @ms(ptr %p) {
entry:
  call void @llvm.memset.p0.i64(ptr align 1 %p, i8 0, i64 64, i1 false)
  ret void
}
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
