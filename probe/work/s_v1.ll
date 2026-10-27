; ModuleID = 'tier_a.f6ecfd4cd34bb32a-cgu.0'
source_filename = "tier_a.f6ecfd4cd34bb32a-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable

; Function Attrs: nofree norecurse nosync nounwind nonlazybind memory(none) uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable

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
  %_4 = icmp ugt i32 %x, -10
  %. = select i1 %_4, i32 -1, i32 -2
  br label %bb12

bb12:                                             ; preds = %bb6, %bb4, %bb2, %start
  %_0.sroa.0.0 = phi i32 [ %., %bb6 ], [ 2, %start ], [ 1, %bb2 ], [ 0, %bb4 ]
  ret i32 %_0.sroa.0.0
}
