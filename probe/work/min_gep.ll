define i64 @gp(ptr %p, i64 %i) {
entry:
  %q = getelementptr inbounds nuw i8, ptr %p, i64 %i
  %v = load i64, ptr %q, align 8
  ret i64 %v
}
