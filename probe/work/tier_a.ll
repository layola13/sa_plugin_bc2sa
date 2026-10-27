; ModuleID = 'tier_a.f6ecfd4cd34bb32a-cgu.0'
source_filename = "tier_a.f6ecfd4cd34bb32a-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable
define noundef double @area_code(i32 noundef %tag, double noundef %a, double noundef %b) unnamed_addr #0 !guid !4 {
start:
  switch i32 %tag, label %bb1 [
    i32 0, label %bb4
    i32 1, label %bb3
  ]

bb4:                                              ; preds = %start
  %_6 = fmul double %a, f0x400921FB54442D18
  %0 = fmul double %a, %_6
  br label %bb1

bb3:                                              ; preds = %start
  %1 = fmul double %a, %b
  br label %bb1

bb1:                                              ; preds = %start, %bb3, %bb4
  %_0.sroa.0.0 = phi double [ %1, %bb3 ], [ %0, %bb4 ], [ -1.000000e+00, %start ]
  ret double %_0.sroa.0.0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable
define noundef range(i32 -3, 4) i32 @classify(i32 noundef %n) unnamed_addr #0 !guid !5 {
start:
  %_9 = icmp slt i32 %n, -99
  br i1 %_9, label %bb15, label %bb3

bb3:                                              ; preds = %start
  %_7 = icmp slt i32 %n, 0
  br i1 %_7, label %bb15, label %bb5

bb5:                                              ; preds = %bb3
  %0 = icmp eq i32 %n, 0
  br i1 %0, label %bb15, label %bb6

bb6:                                              ; preds = %bb5
  %_5 = icmp samesign ult i32 %n, 100
  br i1 %_5, label %bb15, label %bb8

bb15:                                             ; preds = %bb6, %bb8, %bb5, %bb3, %start
  %_0.sroa.0.0 = phi i32 [ 1, %bb6 ], [ -3, %start ], [ -1, %bb3 ], [ %., %bb8 ], [ 0, %bb5 ]
  ret i32 %_0.sroa.0.0

bb8:                                              ; preds = %bb6
  %_3 = icmp samesign ult i32 %n, 1000
  %. = select i1 %_3, i32 2, i32 3
  br label %bb15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable
define noundef i64 @dist2(i64 noundef %x1, i64 noundef %y1, i64 noundef %x2, i64 noundef %y2) unnamed_addr #0 !guid !6 {
start:
  %p = sub i64 %x2, %x1
  %p1 = sub i64 %y2, %y1
  %_7 = mul i64 %p, %p
  %_8 = mul i64 %p1, %p1
  %_0 = add i64 %_8, %_7
  ret i64 %_0
}

; Function Attrs: nofree norecurse nosync nounwind nonlazybind memory(none) uwtable
define noundef i64 @fib(i32 noundef %n) unnamed_addr #1 !guid !7 {
start:
  %_44.not = icmp eq i32 %n, 0
  br i1 %_44.not, label %bb3, label %bb2.preheader

bb2.preheader:                                    ; preds = %start
  %xtraiter = and i32 %n, 7
  %0 = icmp ult i32 %n, 8
  br i1 %0, label %bb2.epil.preheader, label %bb2.preheader.new

bb2.preheader.new:                                ; preds = %bb2.preheader
  %unroll_iter = and i32 %n, -8
  br label %bb2

bb3.loopexit.unr-lcssa:                           ; preds = %bb2
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0
  br i1 %lcmp.mod.not, label %bb3, label %bb2.epil.preheader

bb2.epil.preheader:                               ; preds = %bb3.loopexit.unr-lcssa, %bb2.preheader
  %a.sroa.0.07.epil.init = phi i64 [ 0, %bb2.preheader ], [ %t.6, %bb3.loopexit.unr-lcssa ]
  %b.sroa.0.06.epil.init = phi i64 [ 1, %bb2.preheader ], [ %t.7, %bb3.loopexit.unr-lcssa ]
  %lcmp.mod9 = icmp ne i32 %xtraiter, 0
  tail call void @llvm.assume(i1 %lcmp.mod9)
  br label %bb2.epil

bb2.epil:                                         ; preds = %bb2.epil, %bb2.epil.preheader
  %a.sroa.0.07.epil = phi i64 [ %b.sroa.0.06.epil, %bb2.epil ], [ %a.sroa.0.07.epil.init, %bb2.epil.preheader ]
  %b.sroa.0.06.epil = phi i64 [ %t.epil, %bb2.epil ], [ %b.sroa.0.06.epil.init, %bb2.epil.preheader ]
  %epil.iter = phi i32 [ %epil.iter.next, %bb2.epil ], [ 0, %bb2.epil.preheader ]
  %t.epil = add i64 %a.sroa.0.07.epil, %b.sroa.0.06.epil
  %epil.iter.next = add i32 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i32 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %bb3, label %bb2.epil, !llvm.loop !8

bb3:                                              ; preds = %bb3.loopexit.unr-lcssa, %bb2.epil, %start
  %a.sroa.0.0.lcssa = phi i64 [ 0, %start ], [ %t.6, %bb3.loopexit.unr-lcssa ], [ %b.sroa.0.06.epil, %bb2.epil ]
  ret i64 %a.sroa.0.0.lcssa

bb2:                                              ; preds = %bb2, %bb2.preheader.new
  %a.sroa.0.07 = phi i64 [ 0, %bb2.preheader.new ], [ %t.6, %bb2 ]
  %b.sroa.0.06 = phi i64 [ 1, %bb2.preheader.new ], [ %t.7, %bb2 ]
  %niter = phi i32 [ 0, %bb2.preheader.new ], [ %niter.next.7, %bb2 ]
  %t = add i64 %a.sroa.0.07, %b.sroa.0.06
  %t.1 = add i64 %b.sroa.0.06, %t
  %t.2 = add i64 %t, %t.1
  %t.3 = add i64 %t.1, %t.2
  %t.4 = add i64 %t.2, %t.3
  %t.5 = add i64 %t.3, %t.4
  %t.6 = add i64 %t.4, %t.5
  %t.7 = add i64 %t.5, %t.6
  %niter.next.7 = add i32 %niter, 8
  %niter.ncmp.7 = icmp eq i32 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %bb3.loopexit.unr-lcssa, label %bb2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable
define noundef range(i32 -2, 3) i32 @sign_chain(i32 noundef %x) unnamed_addr #0 !guid !10 {
start:
  %_2 = icmp sgt i32 %x, 10
  br i1 %_2, label %bb12, label %bb2

bb2:                                              ; preds = %start
  %_3 = icmp sgt i32 %x, 0
  br i1 %_3, label %bb12, label %bb4

bb4:                                              ; preds = %bb2
  %0 = icmp eq i32 %x, 0
  br i1 %0, label %bb12, label %bb6

bb6:                                              ; preds = %bb4
  %_4 = icmp samesign ugt i32 %x, -10
  %. = select i1 %_4, i32 -1, i32 -2
  br label %bb12

bb12:                                             ; preds = %bb6, %bb4, %bb2, %start
  %_0.sroa.0.0 = phi i32 [ %., %bb6 ], [ 2, %start ], [ 1, %bb2 ], [ 0, %bb4 ]
  ret i32 %_0.sroa.0.0
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #2

attributes #0 = { mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #1 = { nofree norecurse nosync nounwind nonlazybind memory(none) uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
!2 = !{i32 7, !"uwtable", i32 2}
!3 = !{!"rustc version 1.99.1 (58cf8f9c3 2026-10-13)"}
!4 = !{i64 -4164586842447192940}
!5 = !{i64 -6761552294068852299}
!6 = !{i64 -7391647368428951865}
!7 = !{i64 8667248078361406812}
!8 = distinct !{!8, !9}
!9 = !{!"llvm.loop.unroll.disable"}
!10 = !{i64 -3974336692752064081}
