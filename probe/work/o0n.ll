; ModuleID = 'tier_a.f6ecfd4cd34bb32a-cgu.0'
source_filename = "tier_a.f6ecfd4cd34bb32a-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@alloc_f5a1ce2c58855671cea2bc159fad3577 = private unnamed_addr constant [21 x i8] c"../samples/tier_a.rs\00", align 1, !guid !0
@alloc_b1fe48710255c20a21ab75712c2b7c30 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\00<\00\00\00\15\00\00\00" }>, align 8, !guid !1
@alloc_d96d6463e53f8ea01f7ee05107bf02f3 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\00<\00\00\00!\00\00\00" }>, align 8, !guid !2
@alloc_bd0f0dbf5fea093a3b53bb951626b7df = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\00=\00\00\00\05\00\00\00" }>, align 8, !guid !3
@alloc_bb1639efc2eb500698a664ac3de6f54c = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\00=\00\00\00\11\00\00\00" }>, align 8, !guid !4
@alloc_c6c86e86a682d82ddaf0ce49ad4f1750 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\002\00\00\00\11\00\00\00" }>, align 8, !guid !5
@alloc_58a8419256b1eea9262605319fefacb7 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_f5a1ce2c58855671cea2bc159fad3577, [16 x i8] c"\14\00\00\00\00\00\00\005\00\00\00\09\00\00\00" }>, align 8, !guid !6

; tier_a::shape_of
; Function Attrs: nounwind nonlazybind uwtable
define internal void @_RNvCslcnypCkzrBu_6tier_a8shape_of(ptr sret([24 x i8]) align 8 %_0, i32 %tag, double %a, double %b) unnamed_addr #0 !guid !11 {
start:
  switch i32 %tag, label %bb1 [
    i32 0, label %bb3
    i32 1, label %bb2
  ]

bb1:                                              ; preds = %start
  store i64 2, ptr %_0, align 8
  br label %bb4

bb3:                                              ; preds = %start
  %0 = getelementptr inbounds i8, ptr %_0, i64 8
  store double %a, ptr %0, align 8
  store i64 0, ptr %_0, align 8
  br label %bb4

bb2:                                              ; preds = %start
  %1 = getelementptr inbounds i8, ptr %_0, i64 8
  store double %a, ptr %1, align 8
  %2 = getelementptr inbounds i8, ptr %_0, i64 16
  store double %b, ptr %2, align 8
  store i64 1, ptr %_0, align 8
  br label %bb4

bb4:                                              ; preds = %bb1, %bb2, %bb3
  ret void
}

; Function Attrs: nounwind nonlazybind uwtable
define double @area_code(i32 %tag, double %a, double %b) unnamed_addr #0 !guid !12 {
start:
  %s = alloca [24 x i8], align 8
  %_0 = alloca [8 x i8], align 8
; call tier_a::shape_of
  call void @_RNvCslcnypCkzrBu_6tier_a8shape_of(ptr sret([24 x i8]) align 8 %s, i32 %tag, double %a, double %b) #3
  %_5 = load i64, ptr %s, align 8
  switch i64 %_5, label %bb2 [
    i64 0, label %bb5
    i64 1, label %bb4
    i64 2, label %bb3
  ]

bb2:                                              ; preds = %start
  unreachable

bb5:                                              ; preds = %start
  %0 = getelementptr inbounds i8, ptr %s, i64 8
  %r = load double, ptr %0, align 8
  %_7 = fmul double 3.141592653589793, %r
  %1 = fmul double %_7, %r
  store double %1, ptr %_0, align 8
  br label %bb6

bb4:                                              ; preds = %start
  %2 = getelementptr inbounds i8, ptr %s, i64 8
  %w = load double, ptr %2, align 8
  %3 = getelementptr inbounds i8, ptr %s, i64 16
  %h = load double, ptr %3, align 8
  %4 = fmul double %w, %h
  store double %4, ptr %_0, align 8
  br label %bb6

bb3:                                              ; preds = %start
  store double -1.000000e+00, ptr %_0, align 8
  br label %bb6

bb6:                                              ; preds = %bb3, %bb4, %bb5
  %5 = load double, ptr %_0, align 8
  ret double %5
}

; Function Attrs: nounwind nonlazybind uwtable
define i32 @classify(i32 %n) unnamed_addr #0 !guid !13 {
start:
  %_0 = alloca [4 x i8], align 4
  %_8 = icmp sle i32 -2147483648, %n
  br i1 %_8, label %bb13, label %bb3

bb3:                                              ; preds = %bb13, %start
  %_6 = icmp sle i32 -99, %n
  br i1 %_6, label %bb12, label %bb5

bb13:                                             ; preds = %start
  %_9 = icmp sle i32 %n, -100
  br i1 %_9, label %bb2, label %bb3

bb2:                                              ; preds = %bb13
  store i32 -3, ptr %_0, align 4
  br label %bb15

bb5:                                              ; preds = %bb12, %bb3
  %0 = icmp eq i32 %n, 0
  br i1 %0, label %bb14, label %bb6

bb12:                                             ; preds = %bb3
  %_7 = icmp sle i32 %n, -1
  br i1 %_7, label %bb4, label %bb5

bb4:                                              ; preds = %bb12
  store i32 -1, ptr %_0, align 4
  br label %bb15

bb14:                                             ; preds = %bb5
  store i32 0, ptr %_0, align 4
  br label %bb15

bb6:                                              ; preds = %bb5
  %_4 = icmp sle i32 1, %n
  br i1 %_4, label %bb11, label %bb8

bb15:                                             ; preds = %bb2, %bb4, %bb7, %bb9, %bb1, %bb14
  %1 = load i32, ptr %_0, align 4
  ret i32 %1

bb8:                                              ; preds = %bb11, %bb6
  %_2 = icmp sle i32 100, %n
  br i1 %_2, label %bb10, label %bb1

bb11:                                             ; preds = %bb6
  %_5 = icmp sle i32 %n, 99
  br i1 %_5, label %bb7, label %bb8

bb7:                                              ; preds = %bb11
  store i32 1, ptr %_0, align 4
  br label %bb15

bb1:                                              ; preds = %bb10, %bb8
  store i32 3, ptr %_0, align 4
  br label %bb15

bb10:                                             ; preds = %bb8
  %_3 = icmp sle i32 %n, 999
  br i1 %_3, label %bb9, label %bb1

bb9:                                              ; preds = %bb10
  store i32 2, ptr %_0, align 4
  br label %bb15
}

; Function Attrs: nounwind nonlazybind uwtable
define i64 @dist2(i64 %x1, i64 %y1, i64 %x2, i64 %y2) unnamed_addr #0 !guid !14 {
start:
  %0 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %x2, i64 %x1)
  %_7.0 = extractvalue { i64, i1 } %0, 0
  %_7.1 = extractvalue { i64, i1 } %0, 1
  br i1 %_7.1, label %panic, label %bb1

bb1:                                              ; preds = %start
  %1 = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %y2, i64 %y1)
  %_9.0 = extractvalue { i64, i1 } %1, 0
  %_9.1 = extractvalue { i64, i1 } %1, 1
  br i1 %_9.1, label %panic1, label %bb2

panic:                                            ; preds = %start
; call core::panicking::panic_const::panic_const_sub_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_sub_overflow(ptr align 8 @alloc_b1fe48710255c20a21ab75712c2b7c30) #4
  unreachable

bb2:                                              ; preds = %bb1
  %2 = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %_7.0, i64 %_7.0)
  %_13.0 = extractvalue { i64, i1 } %2, 0
  %_13.1 = extractvalue { i64, i1 } %2, 1
  br i1 %_13.1, label %panic2, label %bb3

panic1:                                           ; preds = %bb1
; call core::panicking::panic_const::panic_const_sub_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_sub_overflow(ptr align 8 @alloc_d96d6463e53f8ea01f7ee05107bf02f3) #4
  unreachable

bb3:                                              ; preds = %bb2
  %3 = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %_9.0, i64 %_9.0)
  %_17.0 = extractvalue { i64, i1 } %3, 0
  %_17.1 = extractvalue { i64, i1 } %3, 1
  br i1 %_17.1, label %panic3, label %bb4

panic2:                                           ; preds = %bb2
; call core::panicking::panic_const::panic_const_mul_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_mul_overflow(ptr align 8 @alloc_bd0f0dbf5fea093a3b53bb951626b7df) #4
  unreachable

bb4:                                              ; preds = %bb3
  %4 = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %_13.0, i64 %_17.0)
  %_18.0 = extractvalue { i64, i1 } %4, 0
  %_18.1 = extractvalue { i64, i1 } %4, 1
  br i1 %_18.1, label %panic4, label %bb5

panic3:                                           ; preds = %bb3
; call core::panicking::panic_const::panic_const_mul_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_mul_overflow(ptr align 8 @alloc_bb1639efc2eb500698a664ac3de6f54c) #4
  unreachable

bb5:                                              ; preds = %bb4
  ret i64 %_18.0

panic4:                                           ; preds = %bb4
; call core::panicking::panic_const::panic_const_add_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_add_overflow(ptr align 8 @alloc_bd0f0dbf5fea093a3b53bb951626b7df) #4
  unreachable
}

; Function Attrs: nounwind nonlazybind uwtable
define i64 @fib(i32 %n) unnamed_addr #0 !guid !15 {
start:
  %i = alloca [4 x i8], align 4
  %b = alloca [8 x i8], align 8
  %a = alloca [8 x i8], align 8
  store i64 0, ptr %a, align 8
  store i64 1, ptr %b, align 8
  store i32 0, ptr %i, align 4
  br label %bb1

bb1:                                              ; preds = %bb4, %start
  %_6 = load i32, ptr %i, align 4
  %_5 = icmp ult i32 %_6, %n
  br i1 %_5, label %bb2, label %bb5

bb5:                                              ; preds = %bb1
  %_0 = load i64, ptr %a, align 8
  ret i64 %_0

bb2:                                              ; preds = %bb1
  %_8 = load i64, ptr %a, align 8
  %_9 = load i64, ptr %b, align 8
  %_10.0 = add i64 %_8, %_9
  %_10.1 = icmp ult i64 %_10.0, %_8
  br i1 %_10.1, label %panic, label %bb3

bb3:                                              ; preds = %bb2
  %_11 = load i64, ptr %b, align 8
  store i64 %_11, ptr %a, align 8
  store i64 %_10.0, ptr %b, align 8
  %0 = load i32, ptr %i, align 4
  %_12.0 = add i32 %0, 1
  %_12.1 = icmp ult i32 %_12.0, %0
  br i1 %_12.1, label %panic1, label %bb4

panic:                                            ; preds = %bb2
; call core::panicking::panic_const::panic_const_add_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_add_overflow(ptr align 8 @alloc_c6c86e86a682d82ddaf0ce49ad4f1750) #4
  unreachable

bb4:                                              ; preds = %bb3
  store i32 %_12.0, ptr %i, align 4
  br label %bb1

panic1:                                           ; preds = %bb3
; call core::panicking::panic_const::panic_const_add_overflow
  call void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_add_overflow(ptr align 8 @alloc_58a8419256b1eea9262605319fefacb7) #4
  unreachable
}

; Function Attrs: nounwind nonlazybind uwtable
define i32 @sign_chain(i32 %x) unnamed_addr #0 !guid !16 {
start:
  %_0 = alloca [4 x i8], align 4
  %_2 = icmp sgt i32 %x, 10
  br i1 %_2, label %bb1, label %bb2

bb2:                                              ; preds = %start
  %_3 = icmp sgt i32 %x, 0
  br i1 %_3, label %bb3, label %bb4

bb1:                                              ; preds = %start
  store i32 2, ptr %_0, align 4
  br label %bb9

bb4:                                              ; preds = %bb2
  %_4 = icmp eq i32 %x, 0
  br i1 %_4, label %bb5, label %bb6

bb3:                                              ; preds = %bb2
  store i32 1, ptr %_0, align 4
  br label %bb9

bb6:                                              ; preds = %bb4
  %_5 = icmp sgt i32 %x, -10
  br i1 %_5, label %bb7, label %bb8

bb5:                                              ; preds = %bb4
  store i32 0, ptr %_0, align 4
  br label %bb9

bb8:                                              ; preds = %bb6
  store i32 -2, ptr %_0, align 4
  br label %bb9

bb7:                                              ; preds = %bb6
  store i32 -1, ptr %_0, align 4
  br label %bb9

bb9:                                              ; preds = %bb1, %bb3, %bb5, %bb7, %bb8
  %0 = load i32, ptr %_0, align 4
  ret i32 %0
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64) #1

; core::panicking::panic_const::panic_const_sub_overflow
; Function Attrs: cold noinline noreturn nounwind nonlazybind uwtable
declare void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_sub_overflow(ptr align 8) unnamed_addr #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64) #1

; core::panicking::panic_const::panic_const_mul_overflow
; Function Attrs: cold noinline noreturn nounwind nonlazybind uwtable
declare void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_mul_overflow(ptr align 8) unnamed_addr #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64) #1

; core::panicking::panic_const::panic_const_add_overflow
; Function Attrs: cold noinline noreturn nounwind nonlazybind uwtable
declare void @_RNvNtNtCskADBYZwJmSU_4core9panicking11panic_const24panic_const_add_overflow(ptr align 8) unnamed_addr #2

attributes #0 = { nounwind nonlazybind uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { cold noinline noreturn nounwind nonlazybind uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #3 = { nounwind }
attributes #4 = { noinline noreturn nounwind }

!llvm.module.flags = !{!7, !8, !9}
!llvm.ident = !{!10}

!0 = !{i64 3232733264229614030}
!1 = !{i64 -1845014146512502170}
!2 = !{i64 4952905830788305502}
!3 = !{i64 -7352942577036553140}
!4 = !{i64 -1161431647876667349}
!5 = !{i64 9188118924454122935}
!6 = !{i64 1209377892949988482}
!7 = !{i32 8, !"PIC Level", i32 2}
!8 = !{i32 2, !"RtLibUseGOT", i32 1}
!9 = !{i32 7, !"uwtable", i32 2}
!10 = !{!"rustc version 1.99.1 (58cf8f9c3 2026-10-13)"}
!11 = !{i64 -3852943254325355112}
!12 = !{i64 -4164586842447192940}
!13 = !{i64 -6761552294068852299}
!14 = !{i64 -7391647368428951865}
!15 = !{i64 8667248078361406812}
!16 = !{i64 -3974336692752064081}
