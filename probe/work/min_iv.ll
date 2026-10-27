define { i64, i1 } @iv(i64 %a) {
entry:
  %r = insertvalue { i64, i1 } undef, i64 %a, 0
  ret { i64, i1 } %r
}
