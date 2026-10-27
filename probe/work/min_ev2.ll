define i64 @evonly(i64 %a) {
entry:
  %p = alloca { i64, i1 }, align 8
  %v = extractvalue { i64, i1 } { i64 5, i1 true }, 0
  ret i64 %v
}
