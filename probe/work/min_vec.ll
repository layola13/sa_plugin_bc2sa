define <2 x i64> @va(<2 x i64> %a, <2 x i64> %b) {
entry:
  %r = add <2 x i64> %a, %b
  ret <2 x i64> %r
}
