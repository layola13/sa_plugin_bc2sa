define double @pd(i32 %x) {
entry:
  %c = icmp eq i32 %x, 0
  br i1 %c, label %a, label %b
a:
  br label %m
b:
  br label %m
m:
  %r = phi double [ 1.500000e+00, %a ], [ -1.000000e+00, %b ]
  ret double %r
}
