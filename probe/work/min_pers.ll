declare i32 @rust_eh_personality(i32, i32, i64, ptr, ptr)
define i64 @pers(i64 %a) personality ptr @rust_eh_personality {
entry:
  ret i64 %a
}
