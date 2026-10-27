define double @hf(double %a) {
entry:
  %r = fmul double %a, f0x400921FB54442D18
  ret double %r
}
