define i64 @un(i64 %a) {
entry:
  %c = icmp eq i64 %a, 0
  br i1 %c, label %ok, label %bad
ok:
  ret i64 %a
bad:
  unreachable
}
