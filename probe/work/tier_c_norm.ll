; ModuleID = 'lib.9b1d2436265349b7-cgu.0'
source_filename = "lib.9b1d2436265349b7-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable
define noundef i64 @fnv1a_fixed() unnamed_addr #0 !guid !4 {
start:
  ret i64 3500526725341250453
}

; Function Attrs: nofree norecurse nosync nounwind nonlazybind memory(none) uwtable
define noundef i64 @fnv1a_stream(i32 noundef %n) unnamed_addr #1 !guid !5 {
start:
  %buf = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(ptr nonnull %buf)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %buf, i8 0, i64 64, i1 false)
  %_58.not = icmp eq i32 %n, 0
  br i1 %_58.not, label %bb8, label %vector.ph.preheader

vector.ph.preheader:                              ; preds = %start
  %0 = getelementptr inbounds nuw i8, ptr %buf, i64 16
  %1 = getelementptr inbounds nuw i8, ptr %buf, i64 32
  %2 = getelementptr inbounds nuw i8, ptr %buf, i64 48
  br label %vector.ph

vector.ph:                                        ; preds = %vector.ph.preheader, %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit
  %i.sroa.0.010 = phi i32 [ %22, %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit ], [ 0, %vector.ph.preheader ]
  %h.sroa.0.09 = phi i64 [ %_10.i.3, %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit ], [ -3750763034362895579, %vector.ph.preheader ]
  %_13 = mul i32 %i.sroa.0.010, 31
  %_12 = add i32 %_13, 13
  %broadcast.splatinsert = insertelement <16 x i32> poison, i32 %_12, i64 0
  %broadcast.splat = shufflevector <16 x i32> %broadcast.splatinsert, <16 x i32> poison, <16 x i32> zeroinitializer
  %3 = add <16 x i32> %broadcast.splat, <i32 0, i32 7, i32 14, i32 21, i32 28, i32 35, i32 42, i32 49, i32 56, i32 63, i32 70, i32 77, i32 84, i32 91, i32 98, i32 105>
  %4 = urem <16 x i32> %3, splat (i32 251)
  %5 = trunc nuw <16 x i32> %4 to <16 x i8>
  store <16 x i8> %5, ptr %buf, align 16
  %6 = add <16 x i32> %broadcast.splat, <i32 112, i32 119, i32 126, i32 133, i32 140, i32 147, i32 154, i32 161, i32 168, i32 175, i32 182, i32 189, i32 196, i32 203, i32 210, i32 217>
  %7 = urem <16 x i32> %6, splat (i32 251)
  %8 = trunc nuw <16 x i32> %7 to <16 x i8>
  store <16 x i8> %8, ptr %0, align 16
  %9 = add <16 x i32> %broadcast.splat, <i32 224, i32 231, i32 238, i32 245, i32 252, i32 259, i32 266, i32 273, i32 280, i32 287, i32 294, i32 301, i32 308, i32 315, i32 322, i32 329>
  %10 = urem <16 x i32> %9, splat (i32 251)
  %11 = trunc nuw <16 x i32> %10 to <16 x i8>
  store <16 x i8> %11, ptr %1, align 16
  %12 = add <16 x i32> %broadcast.splat, <i32 336, i32 343, i32 350, i32 357, i32 364, i32 371, i32 378, i32 385, i32 392, i32 399, i32 406, i32 413, i32 420, i32 427, i32 434, i32 441>
  %13 = urem <16 x i32> %12, splat (i32 251)
  %14 = trunc nuw <16 x i32> %13 to <16 x i8>
  store <16 x i8> %14, ptr %2, align 16
  br label %bb3.i

bb8:                                              ; preds = %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit, %start
  %h.sroa.0.0.lcssa = phi i64 [ -3750763034362895579, %start ], [ %_10.i.3, %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit ]
  call void @llvm.lifetime.end.p0(ptr nonnull %buf)
  ret i64 %h.sroa.0.0.lcssa

bb3.i:                                            ; preds = %bb3.i, %vector.ph
  %hash.sroa.0.05.i = phi i64 [ %h.sroa.0.09, %vector.ph ], [ %_10.i.3, %bb3.i ]
  %iter.sroa.0.04.i.idx = phi i64 [ 0, %vector.ph ], [ %iter.sroa.0.04.i.add.3, %bb3.i ]
  %iter.sroa.0.04.i.ptr = getelementptr inbounds nuw i8, ptr %buf, i64 %iter.sroa.0.04.i.idx
  %_9.i = load i8, ptr %iter.sroa.0.04.i.ptr, align 4
  %_8.i = zext i8 %_9.i to i64
  %15 = xor i64 %hash.sroa.0.05.i, %_8.i
  %_10.i = mul i64 %15, 1099511628211
  %16 = getelementptr inbounds nuw i8, ptr %buf, i64 %iter.sroa.0.04.i.idx
  %iter.sroa.0.04.i.ptr.1 = getelementptr inbounds nuw i8, ptr %16, i64 1
  %_9.i.1 = load i8, ptr %iter.sroa.0.04.i.ptr.1, align 1
  %_8.i.1 = zext i8 %_9.i.1 to i64
  %17 = xor i64 %_10.i, %_8.i.1
  %_10.i.1 = mul i64 %17, 1099511628211
  %18 = getelementptr inbounds nuw i8, ptr %buf, i64 %iter.sroa.0.04.i.idx
  %iter.sroa.0.04.i.ptr.2 = getelementptr inbounds nuw i8, ptr %18, i64 2
  %_9.i.2 = load i8, ptr %iter.sroa.0.04.i.ptr.2, align 2
  %_8.i.2 = zext i8 %_9.i.2 to i64
  %19 = xor i64 %_10.i.1, %_8.i.2
  %_10.i.2 = mul i64 %19, 1099511628211
  %20 = getelementptr inbounds nuw i8, ptr %buf, i64 %iter.sroa.0.04.i.idx
  %iter.sroa.0.04.i.ptr.3 = getelementptr inbounds nuw i8, ptr %20, i64 3
  %iter.sroa.0.04.i.add.3 = add nuw nsw i64 %iter.sroa.0.04.i.idx, 4
  %_9.i.3 = load i8, ptr %iter.sroa.0.04.i.ptr.3, align 1
  %_8.i.3 = zext i8 %_9.i.3 to i64
  %21 = xor i64 %_10.i.2, %_8.i.3
  %_10.i.3 = mul i64 %21, 1099511628211
  %_23.i.3 = icmp eq i64 %iter.sroa.0.04.i.add.3, 64
  br i1 %_23.i.3, label %_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit, label %bb3.i

_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write.exit: ; preds = %bb3.i
  %22 = add nuw i32 %i.sroa.0.010, 1
  %exitcond11.not = icmp eq i32 %22, %n
  br i1 %exitcond11.not, label %bb8, label %vector.ph
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind nonlazybind willreturn memory(none) uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #1 = { nofree norecurse nosync nounwind nonlazybind memory(none) uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{i32 2, !"RtLibUseGOT", i32 1}
!2 = !{i32 7, !"uwtable", i32 2}
!3 = !{!"rustc version 1.99.1 (58cf8f9c3 2026-10-13)"}
!4 = !{i64 -7007009911110084731}
!5 = !{i64 4520981930174190879}
!6 = !{!7}
!7 = distinct !{!7, !8, !"_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write: %bytes.0"}
!8 = distinct !{!8, !"_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write"}
!9 = !{!10}
!10 = distinct !{!10, !8, !"_RNvXs0_NtCsdjFn5GDoF3D_3lib3fnvNtB5_9FnvHasherNtNtCskADBYZwJmSU_4core4hash6Hasher5write: %self"}
!11 = !{}
