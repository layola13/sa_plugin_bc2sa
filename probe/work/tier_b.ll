; ModuleID = 'tier_b.b6ecbca91df9d46-cgu.0'
source_filename = "tier_b.b6ecbca91df9d46-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@alloc_e342eacdbf38ee6e7c7878ca690b4e0f = private unnamed_addr constant [23 x i8] c"alpha,beta,,gamma,delta", align 1, !guid !0

; <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
; Function Attrs: cold nounwind nonlazybind uwtable
define internal fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 captures(none) dereferenceable(16) %slf, i64 noundef %len, i64 noundef %additional, i64 noundef range(i64 1, 9) %elem_layout.0, i64 noundef range(i64 1, 17) %elem_layout.1) unnamed_addr #0 personality ptr @rust_eh_personality !guid !5 {
start:
  %self3.i = alloca [24 x i8], align 8
  tail call void @llvm.experimental.noalias.scope.decl(metadata !6)
  %_25.0.i = add i64 %additional, %len
  %_25.1.i = icmp ult i64 %_25.0.i, %len
  br i1 %_25.1.i, label %bb2, label %bb9.i

bb9.i:                                            ; preds = %start
  %self5.i = load i64, ptr %slf, align 8, !range !9, !alias.scope !6, !noundef !10
  %v16.i = shl nuw i64 %self5.i, 1
  %..i.i = tail call noundef i64 @llvm.umax.i64(i64 %_25.0.i, i64 range(i64 0, -1) %v16.i)
  %0 = icmp eq i64 %elem_layout.1, 1
  %v1.sroa.0.0.i = select i1 %0, i64 8, i64 4
  %..i15.i = tail call noundef i64 @llvm.umax.i64(i64 %..i.i, i64 range(i64 0, -1) %v1.sroa.0.0.i)
  call void @llvm.lifetime.start.p0(ptr nonnull %self3.i), !noalias !6
; call <alloc::raw_vec::RawVecInner>::finish_grow
  call fastcc void @_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner11finish_growCsYR6quqRMAk_6tier_b(ptr noalias nofree noundef sret([24 x i8]) align 8 captures(none) dereferenceable(24) %self3.i, ptr noalias nofree noundef nonnull readonly align 8 captures(address, read_provenance) dereferenceable(16) %slf, i64 noundef %..i15.i, i64 noundef range(i64 1, 9) %elem_layout.0, i64 noundef range(i64 1, 17) %elem_layout.1) #13
  %_37.i = load i64, ptr %self3.i, align 8, !range !11, !noalias !6, !noundef !10
  %1 = trunc nuw i64 %_37.i to i1
  %2 = getelementptr inbounds nuw i8, ptr %self3.i, i64 8
  br i1 %1, label %bb18.i, label %bb3

bb18.i:                                           ; preds = %bb9.i
  %e.0.i = load i64, ptr %2, align 8, !range !12, !noalias !6, !noundef !10
  %3 = getelementptr inbounds nuw i8, ptr %self3.i, i64 16
  %e.1.i = load i64, ptr %3, align 8, !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %self3.i), !noalias !6
  br label %bb2

bb2:                                              ; preds = %bb18.i, %start
  %_0.sroa.5.0.i.ph = phi i64 [ undef, %start ], [ %e.1.i, %bb18.i ]
  %_0.sroa.0.0.i.ph = phi i64 [ 0, %start ], [ %e.0.i, %bb18.i ]
; call alloc::raw_vec::handle_error
  tail call void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef %_0.sroa.0.0.i.ph, i64 %_0.sroa.5.0.i.ph) #14
  unreachable

bb3:                                              ; preds = %bb9.i
  %v.0.i = load ptr, ptr %2, align 8, !noalias !6, !nonnull !10, !noundef !10
  call void @llvm.lifetime.end.p0(ptr nonnull %self3.i), !noalias !6
  %4 = getelementptr inbounds nuw i8, ptr %slf, i64 8
  store ptr %v.0.i, ptr %4, align 8, !alias.scope !6
  %5 = icmp sgt i64 %..i15.i, -1
  tail call void @llvm.assume(i1 %5)
  store i64 %..i15.i, ptr %slf, align 8, !alias.scope !6
  ret void
}

; <alloc::raw_vec::RawVec<u64>>::grow_one
; Function Attrs: cold noinline nounwind nonlazybind uwtable
define void @_RNvMs4_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyE8grow_oneCsYR6quqRMAk_6tier_b(ptr noalias nofree noundef align 8 captures(none) dereferenceable(16) %self) unnamed_addr #1 personality ptr @rust_eh_personality !guid !13 {
start:
  %self3.i = alloca [24 x i8], align 8
  %self1 = load i64, ptr %self, align 8, !range !9, !noundef !10
  tail call void @llvm.experimental.noalias.scope.decl(metadata !14)
  %v16.i = shl nuw i64 %self1, 1
  %0 = tail call i64 @llvm.umax.i64(i64 %v16.i, i64 4)
  call void @llvm.lifetime.start.p0(ptr nonnull %self3.i), !noalias !14
; call <alloc::raw_vec::RawVecInner>::finish_grow
  call fastcc void @_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner11finish_growCsYR6quqRMAk_6tier_b(ptr noalias nofree noundef sret([24 x i8]) align 8 captures(none) dereferenceable(24) %self3.i, ptr noalias nofree noundef nonnull readonly align 8 captures(address, read_provenance) dereferenceable(16) %self, i64 noundef %0, i64 noundef 8, i64 noundef 8) #13
  %_37.i = load i64, ptr %self3.i, align 8, !range !11, !noalias !14, !noundef !10
  %1 = trunc nuw i64 %_37.i to i1
  %2 = getelementptr inbounds nuw i8, ptr %self3.i, i64 8
  br i1 %1, label %bb18.i, label %bb3

bb18.i:                                           ; preds = %start
  %e.0.i = load i64, ptr %2, align 8, !range !12, !noalias !14, !noundef !10
  %3 = getelementptr inbounds nuw i8, ptr %self3.i, i64 16
  %e.1.i = load i64, ptr %3, align 8, !noalias !14
  call void @llvm.lifetime.end.p0(ptr nonnull %self3.i), !noalias !14
; call alloc::raw_vec::handle_error
  tail call void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef %e.0.i, i64 %e.1.i) #14
  unreachable

bb3:                                              ; preds = %start
  %v.0.i = load ptr, ptr %2, align 8, !noalias !14, !nonnull !10, !noundef !10
  call void @llvm.lifetime.end.p0(ptr nonnull %self3.i), !noalias !14
  %4 = getelementptr inbounds nuw i8, ptr %self, i64 8
  store ptr %v.0.i, ptr %4, align 8, !alias.scope !14
  %5 = icmp sgt i64 %0, -1
  tail call void @llvm.assume(i1 %5)
  store i64 %0, ptr %self, align 8, !alias.scope !14
  ret void
}

; <alloc::raw_vec::RawVecInner>::finish_grow
; Function Attrs: cold nounwind nonlazybind uwtable
define internal fastcc void @_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner11finish_growCsYR6quqRMAk_6tier_b(ptr dead_on_unwind noalias nofree noundef nonnull writable writeonly sret([24 x i8]) align 8 captures(none) dereferenceable(24) initializes((0, 8)) %_0, ptr noalias nofree noundef nonnull readonly align 8 captures(none) dereferenceable(16) %self, i64 noundef %cap, i64 noundef range(i64 1, 9) %elem_layout.0, i64 noundef range(i64 1, 17) %elem_layout.1) unnamed_addr #0 !guid !17 {
start:
  %0 = tail call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %elem_layout.1, i64 %cap)
  %_32.0 = extractvalue { i64, i1 } %0, 0
  %_32.1 = extractvalue { i64, i1 } %0, 1
  %_39 = sub nuw i64 -9223372036854775808, %elem_layout.0
  %_37.not = icmp ugt i64 %_32.0, %_39
  %or.cond = select i1 %_32.1, i1 true, i1 %_37.not, !prof !18
  br i1 %or.cond, label %bb8, label %bb12, !prof !18

bb12:                                             ; preds = %start
  %self1.i = load i64, ptr %self, align 8, !range !9, !alias.scope !19, !noalias !22, !noundef !10
  %1 = icmp eq i64 %self1.i, 0
  br i1 %1, label %bb5, label %bb3

bb3:                                              ; preds = %bb12
  %alloc_size.i = mul nuw i64 %self1.i, %elem_layout.1
  %2 = getelementptr inbounds nuw i8, ptr %self, i64 8
  %self3.i = load ptr, ptr %2, align 8, !alias.scope !19, !noalias !22, !nonnull !10, !noundef !10
  %cond.i.i = icmp uge i64 %_32.0, %alloc_size.i
  tail call void @llvm.assume(i1 %cond.i.i)
; call __rustc::__rust_realloc
  %raw_ptr.i.i = tail call noundef ptr @_RNvCs5fGHjzWXRav_7___rustc14___rust_realloc(ptr noundef nonnull %self3.i, i64 noundef %alloc_size.i, i64 noundef range(i64 1, 9) %elem_layout.0, i64 noundef range(i64 0, -9223372036854775808) %_32.0) #13
  br label %bb7

bb5:                                              ; preds = %bb12
  %3 = icmp eq i64 %_32.0, 0
  br i1 %3, label %bb7.thread, label %bb4.i.i11

bb7.thread:                                       ; preds = %bb5
  %self3.i.i = inttoptr i64 %elem_layout.0 to ptr
  br label %bb19

bb4.i.i11:                                        ; preds = %bb5
; call __rustc::__rust_no_alloc_shim_is_unstable_v2
  tail call void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() #13
; call __rustc::__rust_alloc
  %4 = tail call noundef ptr @_RNvCs5fGHjzWXRav_7___rustc12___rust_alloc(i64 noundef range(i64 0, -9223372036854775808) %_32.0, i64 noundef range(i64 1, 9) %elem_layout.0) #13
  br label %bb7

bb7:                                              ; preds = %bb4.i.i11, %bb3
  %raw_ptr.i.i.pn = phi ptr [ %raw_ptr.i.i, %bb3 ], [ %4, %bb4.i.i11 ]
  %5 = icmp eq ptr %raw_ptr.i.i.pn, null
  br i1 %5, label %bb18, label %bb19

bb18:                                             ; preds = %bb7
  %6 = getelementptr inbounds nuw i8, ptr %_0, i64 8
  store i64 %elem_layout.0, ptr %6, align 8
  br label %bb8

bb19:                                             ; preds = %bb7.thread, %bb7
  %raw_ptr.i.i.pn21 = phi ptr [ %self3.i.i, %bb7.thread ], [ %raw_ptr.i.i.pn, %bb7 ]
  %7 = getelementptr inbounds nuw i8, ptr %_0, i64 8
  store ptr %raw_ptr.i.i.pn21, ptr %7, align 8
  br label %bb8

bb8:                                              ; preds = %start, %bb19, %bb18
  %.sink23 = phi i64 [ 16, %bb19 ], [ 16, %bb18 ], [ 8, %start ]
  %_32.0.sink = phi i64 [ %_32.0, %bb19 ], [ %_32.0, %bb18 ], [ 0, %start ]
  %.sink = phi i64 [ 0, %bb19 ], [ 1, %bb18 ], [ 1, %start ]
  %8 = getelementptr inbounds nuw i8, ptr %_0, i64 %.sink23
  store i64 %_32.0.sink, ptr %8, align 8
  store i64 %.sink, ptr %_0, align 8
  ret void
}

; Function Attrs: cold nounwind nonlazybind uwtable
define noundef i64 @string_build() unnamed_addr #0 personality ptr @rust_eh_personality !guid !24 {
start:
  %s = alloca [24 x i8], align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %s)
; call __rustc::__rust_no_alloc_shim_is_unstable_v2
  tail call void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() #13, !noalias !25
; call __rustc::__rust_alloc
  %0 = tail call noundef dereferenceable_or_null(2) ptr @_RNvCs5fGHjzWXRav_7___rustc12___rust_alloc(i64 noundef range(i64 0, -9223372036854775808) 2, i64 noundef range(i64 1, 9) 1) #13, !noalias !25
  %1 = icmp eq ptr %0, null
  br i1 %1, label %bb11, label %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit

bb11:                                             ; preds = %start
; call alloc::raw_vec::handle_error
  tail call void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef 1, i64 2) #14
  unreachable

_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit: ; preds = %start
  store i16 25185, ptr %0, align 1
  store i64 2, ptr %s, align 8
  %_16.sroa.4.0.s.sroa_idx = getelementptr inbounds nuw i8, ptr %s, i64 8
  store ptr %0, ptr %_16.sroa.4.0.s.sroa_idx, align 8
  %_16.sroa.6.0.s.sroa_idx = getelementptr inbounds nuw i8, ptr %s, i64 16
  store i64 2, ptr %_16.sroa.6.0.s.sroa_idx, align 8
  tail call void @llvm.experimental.noalias.scope.decl(metadata !28)
; call <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
  call fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %s, i64 noundef 2, i64 noundef 2, i64 noundef 1, i64 noundef 1) #13
  %len.pre.i = load i64, ptr %_16.sroa.6.0.s.sroa_idx, align 8, !alias.scope !28
  %_10.i = icmp sgt i64 %len.pre.i, -1
  tail call void @llvm.assume(i1 %_10.i)
  %_11.i = load ptr, ptr %_16.sroa.4.0.s.sroa_idx, align 8, !alias.scope !28, !nonnull !10, !noundef !10
  %dst.i = getelementptr inbounds nuw i8, ptr %_11.i, i64 %len.pre.i
  store i16 25699, ptr %dst.i, align 1, !noalias !28
  %2 = add nuw nsw i64 %len.pre.i, 2
  store i64 %2, ptr %_16.sroa.6.0.s.sroa_idx, align 8, !alias.scope !28
  tail call void @llvm.experimental.noalias.scope.decl(metadata !31)
  %self2.i.i4 = load i64, ptr %s, align 8, !range !9, !alias.scope !34, !noundef !10
  %_7.i.i5 = icmp eq i64 %self2.i.i4, %2
  br i1 %_7.i.i5, label %bb1.i.i6, label %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit, !prof !37

bb16.preheader:                                   ; preds = %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit.1, %bb1.i.i6.2
  %_19.i.2 = load ptr, ptr %_16.sroa.4.0.s.sroa_idx, align 8, !alias.scope !38, !nonnull !10, !noundef !10
  %_8.i.2 = getelementptr inbounds nuw i8, ptr %_19.i.2, i64 %new_len.i.1
  store i8 120, ptr %_8.i.2, align 1, !noalias !38
  %new_len.i.2 = add nuw i64 %len.pre.i, 5
  %xtraiter = and i64 %new_len.i.2, 7
  %3 = icmp samesign ult i64 %len.pre.i, 3
  br i1 %3, label %bb16.epil.preheader, label %bb16.preheader.new

bb16.preheader.new:                               ; preds = %bb16.preheader
  %unroll_iter = and i64 %new_len.i.2, -8
  br label %bb16

bb1.i.i6:                                         ; preds = %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit
; call <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
  call fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %s, i64 noundef %2, i64 noundef 1, i64 noundef 1, i64 noundef 1) #13
  %_19.i.pre = load ptr, ptr %_16.sroa.4.0.s.sroa_idx, align 8, !alias.scope !31
  %self2.i.i4.1.pre = load i64, ptr %s, align 8, !range !9, !alias.scope !40
  br label %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit

_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit: ; preds = %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit, %bb1.i.i6
  %self2.i.i4.1 = phi i64 [ %self2.i.i4, %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit ], [ %self2.i.i4.1.pre, %bb1.i.i6 ]
  %_19.i = phi ptr [ %_11.i, %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b.exit ], [ %_19.i.pre, %bb1.i.i6 ]
  %_8.i = getelementptr inbounds nuw i8, ptr %_19.i, i64 %2
  store i8 120, ptr %_8.i, align 1, !noalias !31
  %new_len.i = add nuw nsw i64 %len.pre.i, 3
  store i64 %new_len.i, ptr %_16.sroa.6.0.s.sroa_idx, align 8, !alias.scope !31
  tail call void @llvm.experimental.noalias.scope.decl(metadata !42)
  %_7.i.i5.1 = icmp eq i64 %self2.i.i4.1, %new_len.i
  br i1 %_7.i.i5.1, label %bb1.i.i6.1, label %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit.1, !prof !37

bb1.i.i6.1:                                       ; preds = %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit
; call <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
  call fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %s, i64 noundef %self2.i.i4.1, i64 noundef 1, i64 noundef 1, i64 noundef 1) #13
  %_19.i.1.pre = load ptr, ptr %_16.sroa.4.0.s.sroa_idx, align 8, !alias.scope !42
  br label %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit.1

_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit.1: ; preds = %bb1.i.i6.1, %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit
  %_19.i.1 = phi ptr [ %_19.i.1.pre, %bb1.i.i6.1 ], [ %_19.i, %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit ]
  %_8.i.1 = getelementptr inbounds nuw i8, ptr %_19.i.1, i64 %new_len.i
  store i8 120, ptr %_8.i.1, align 1, !noalias !42
  %new_len.i.1 = add nuw nsw i64 %len.pre.i, 4
  store i64 %new_len.i.1, ptr %_16.sroa.6.0.s.sroa_idx, align 8, !alias.scope !42
  tail call void @llvm.experimental.noalias.scope.decl(metadata !38)
  %self2.i.i4.2 = load i64, ptr %s, align 8, !range !9, !alias.scope !43, !noundef !10
  %_7.i.i5.2 = icmp eq i64 %self2.i.i4.2, %new_len.i.1
  br i1 %_7.i.i5.2, label %bb1.i.i6.2, label %bb16.preheader, !prof !37

bb1.i.i6.2:                                       ; preds = %_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push.exit.1
; call <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
  call fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %s, i64 noundef %new_len.i.1, i64 noundef 1, i64 noundef 1, i64 noundef 1) #13
  br label %bb16.preheader

bb16:                                             ; preds = %bb16, %bb16.preheader.new
  %sum.sroa.0.016 = phi i64 [ 0, %bb16.preheader.new ], [ %11, %bb16 ]
  %iter.sroa.0.015 = phi ptr [ %_19.i.2, %bb16.preheader.new ], [ %_72.7, %bb16 ]
  %niter = phi i64 [ 0, %bb16.preheader.new ], [ %niter.next.7, %bb16 ]
  %_72 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 1
  %_12 = load i8, ptr %iter.sroa.0.015, align 1, !noundef !10
  %_11 = zext i8 %_12 to i64
  %4 = add i64 %sum.sroa.0.016, %_11
  %_72.1 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 2
  %_12.1 = load i8, ptr %_72, align 1, !noundef !10
  %_11.1 = zext i8 %_12.1 to i64
  %5 = add i64 %4, %_11.1
  %_72.2 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 3
  %_12.2 = load i8, ptr %_72.1, align 1, !noundef !10
  %_11.2 = zext i8 %_12.2 to i64
  %6 = add i64 %5, %_11.2
  %_72.3 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 4
  %_12.3 = load i8, ptr %_72.2, align 1, !noundef !10
  %_11.3 = zext i8 %_12.3 to i64
  %7 = add i64 %6, %_11.3
  %_72.4 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 5
  %_12.4 = load i8, ptr %_72.3, align 1, !noundef !10
  %_11.4 = zext i8 %_12.4 to i64
  %8 = add i64 %7, %_11.4
  %_72.5 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 6
  %_12.5 = load i8, ptr %_72.4, align 1, !noundef !10
  %_11.5 = zext i8 %_12.5 to i64
  %9 = add i64 %8, %_11.5
  %_72.6 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 7
  %_12.6 = load i8, ptr %_72.5, align 1, !noundef !10
  %_11.6 = zext i8 %_12.6 to i64
  %10 = add i64 %9, %_11.6
  %_72.7 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015, i64 8
  %_12.7 = load i8, ptr %_72.6, align 1, !noundef !10
  %_11.7 = zext i8 %_12.7 to i64
  %11 = add i64 %10, %_11.7
  %niter.next.7 = add i64 %niter, 8
  %niter.ncmp.7 = icmp eq i64 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %bb15.unr-lcssa, label %bb16

bb15.unr-lcssa:                                   ; preds = %bb16
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod.not, label %bb15, label %bb16.epil.preheader

bb16.epil.preheader:                              ; preds = %bb15.unr-lcssa, %bb16.preheader
  %sum.sroa.0.016.epil.init = phi i64 [ 0, %bb16.preheader ], [ %11, %bb15.unr-lcssa ]
  %iter.sroa.0.015.epil.init = phi ptr [ %_19.i.2, %bb16.preheader ], [ %_72.7, %bb15.unr-lcssa ]
  %lcmp.mod23 = icmp ne i64 %xtraiter, 0
  tail call void @llvm.assume(i1 %lcmp.mod23)
  br label %bb16.epil

bb16.epil:                                        ; preds = %bb16.epil, %bb16.epil.preheader
  %sum.sroa.0.016.epil = phi i64 [ %12, %bb16.epil ], [ %sum.sroa.0.016.epil.init, %bb16.epil.preheader ]
  %iter.sroa.0.015.epil = phi ptr [ %_72.epil, %bb16.epil ], [ %iter.sroa.0.015.epil.init, %bb16.epil.preheader ]
  %epil.iter = phi i64 [ %epil.iter.next, %bb16.epil ], [ 0, %bb16.epil.preheader ]
  %_72.epil = getelementptr inbounds nuw i8, ptr %iter.sroa.0.015.epil, i64 1
  %_12.epil = load i8, ptr %iter.sroa.0.015.epil, align 1, !noundef !10
  %_11.epil = zext i8 %_12.epil to i64
  %12 = add i64 %sum.sroa.0.016.epil, %_11.epil
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %bb15, label %bb16.epil, !llvm.loop !44

bb15:                                             ; preds = %bb16.epil, %bb15.unr-lcssa
  %.lcssa = phi i64 [ %11, %bb15.unr-lcssa ], [ %12, %bb16.epil ]
  %_74 = icmp sgt i64 %new_len.i.2, -1
  tail call void @llvm.assume(i1 %_74)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !46)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !49)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !52)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !55)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !58)
  %self1.i.i.i.i.i.i = load i64, ptr %s, align 8, !range !9, !alias.scope !61, !noalias !64, !noundef !10
  %13 = icmp eq i64 %self1.i.i.i.i.i.i, 0
  br i1 %13, label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueNtNtCsgFX3jaOk65H_5alloc6string6StringECsYR6quqRMAk_6tier_b.exit, label %bb2.i.i.i.i.i

bb2.i.i.i.i.i:                                    ; preds = %bb15
; call __rustc::__rust_dealloc
  tail call void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr noundef nonnull %_19.i.2, i64 noundef %self1.i.i.i.i.i.i, i64 noundef range(i64 1, -9223372036854775807) 1) #13, !noalias !66
  br label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueNtNtCsgFX3jaOk65H_5alloc6string6StringECsYR6quqRMAk_6tier_b.exit

_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueNtNtCsgFX3jaOk65H_5alloc6string6StringECsYR6quqRMAk_6tier_b.exit: ; preds = %bb15, %bb2.i.i.i.i.i
  %_13 = mul i64 %new_len.i.2, 1000
  %_0 = add i64 %.lcssa, %_13
  call void @llvm.lifetime.end.p0(ptr nonnull %s)
  ret i64 %_0
}

; Function Attrs: nounwind nonlazybind uwtable
define noundef i64 @string_fmt() unnamed_addr #2 personality ptr @rust_eh_personality !guid !67 {
_RINvMNtCskADBYZwJmSU_4core6optionINtB3_6OptionReE11map_or_elseNtNtCsgFX3jaOk65H_5alloc6string6StringNCNvNtB12_3fmt6format0NvYeNtNtB12_6borrow7ToOwned8to_ownedECsYR6quqRMAk_6tier_b.exit:
; call __rustc::__rust_no_alloc_shim_is_unstable_v2
  tail call void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() #13, !noalias !68
  ret i64 4208
}

; Function Attrs: nounwind nonlazybind uwtable
define noundef i64 @string_split_count() unnamed_addr #2 personality ptr @rust_eh_personality !guid !82 {
bb14.lr.ph.i.i.i.i:
  %_19.i = alloca [72 x i8], align 8
  %vector.i = alloca [24 x i8], align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %vector.i), !noalias !83
  br label %bb14.i.i.i.i

bb14.i.i.i.i:                                     ; preds = %bb31.i.i.i.i, %bb14.lr.ph.i.i.i.i
  %0 = phi i64 [ 0, %bb14.lr.ph.i.i.i.i ], [ %7, %bb31.i.i.i.i ]
  %new_len.i.i.i.i = sub nuw nsw i64 23, %0
  %_46.i.i.i.i = getelementptr inbounds nuw i8, ptr @alloc_e342eacdbf38ee6e7c7878ca690b4e0f, i64 %0
  %_3.i.i.i.i.i = icmp samesign ugt i64 %0, 7
  br i1 %_3.i.i.i.i.i, label %bb6.preheader.i.i.i.i.i, label %bb2.i.i.i.i.i

bb6.preheader.i.i.i.i.i:                          ; preds = %bb14.i.i.i.i
  %_98.not.i.i.i.i.i = icmp eq i64 %0, 23
  br i1 %_98.not.i.i.i.i.i, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i, label %bb8.i.i.i.i.i

bb2.i.i.i.i.i:                                    ; preds = %bb14.i.i.i.i
; call core::slice::memchr::memchr_aligned
  %1 = tail call { i64, i64 } @_RNvNtNtCskADBYZwJmSU_4core5slice6memchr14memchr_aligned(i8 noundef 44, ptr noalias nofree noundef nonnull readonly captures(address, read_provenance) %_46.i.i.i.i, i64 noundef range(i64 0, -9223372036854775808) %new_len.i.i.i.i) #13, !noalias !87
  %2 = extractvalue { i64, i64 } %1, 0
  %3 = extractvalue { i64, i64 } %1, 1
  %4 = trunc nuw i64 %2 to i1
  br i1 %4, label %bb4.i.i.i.i, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i

bb8.i.i.i.i.i:                                    ; preds = %bb6.preheader.i.i.i.i.i, %bb10.i.i.i.i.i
  %i.sroa.0.09.i.i.i.i.i = phi i64 [ %6, %bb10.i.i.i.i.i ], [ 0, %bb6.preheader.i.i.i.i.i ]
  %5 = getelementptr inbounds nuw i8, ptr %_46.i.i.i.i, i64 %i.sroa.0.09.i.i.i.i.i
  %_12.i.i.i.i.i = load i8, ptr %5, align 1, !alias.scope !95, !noalias !87, !noundef !10
  %_11.i.i.i.i.i = icmp eq i8 %_12.i.i.i.i.i, 44
  br i1 %_11.i.i.i.i.i, label %bb4.i.i.i.i, label %bb10.i.i.i.i.i

bb10.i.i.i.i.i:                                   ; preds = %bb8.i.i.i.i.i
  %6 = add nuw nsw i64 %i.sroa.0.09.i.i.i.i.i, 1
  %exitcond.not.i.i.i.i.i = icmp eq i64 %6, %new_len.i.i.i.i
  br i1 %exitcond.not.i.i.i.i.i, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i, label %bb8.i.i.i.i.i

bb4.i.i.i.i:                                      ; preds = %bb8.i.i.i.i.i, %bb2.i.i.i.i.i
  %result.sroa.5.0.i.i.i.i.i = phi i64 [ %3, %bb2.i.i.i.i.i ], [ %i.sroa.0.09.i.i.i.i.i, %bb8.i.i.i.i.i ]
  %cond.i.i.i.i.i = icmp ult i64 %result.sroa.5.0.i.i.i.i.i, %new_len.i.i.i.i
  tail call void @llvm.assume(i1 %cond.i.i.i.i.i)
  %_17.i.i.i.i = add nuw nsw i64 %0, 1
  %7 = add nuw nsw i64 %_17.i.i.i.i, %result.sroa.5.0.i.i.i.i.i
  %_56.not.i.i.i.i = icmp ugt i64 %7, 23
  br i1 %_56.not.i.i.i.i, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i, label %bb31.i.i.i.i

bb31.i.i.i.i:                                     ; preds = %bb4.i.i.i.i
  %found_char.i.i.i.i = add nuw nsw i64 %0, %result.sroa.5.0.i.i.i.i.i
  %8 = shl nuw i64 1, %found_char.i.i.i.i
  %9 = and i64 %8, 134176
  %_28.i.i.i.i.not = icmp eq i64 %9, 0
  br i1 %_28.i.i.i.i.not, label %bb14.i.i.i.i, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i

_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i: ; preds = %bb10.i.i.i.i.i, %bb2.i.i.i.i.i, %bb6.preheader.i.i.i.i.i, %bb4.i.i.i.i, %bb31.i.i.i.i
  %_2.sroa.8.0 = phi i64 [ %7, %bb31.i.i.i.i ], [ 23, %bb10.i.i.i.i.i ], [ 23, %bb6.preheader.i.i.i.i.i ], [ 23, %bb2.i.i.i.i.i ], [ %7, %bb4.i.i.i.i ]
  %_2.sroa.16.0 = phi i8 [ 0, %bb31.i.i.i.i ], [ 1, %bb4.i.i.i.i ], [ 1, %bb6.preheader.i.i.i.i.i ], [ 1, %bb2.i.i.i.i.i ], [ 1, %bb10.i.i.i.i.i ]
  %_2.sroa.0.0 = phi i64 [ %7, %bb31.i.i.i.i ], [ 0, %bb4.i.i.i.i ], [ 0, %bb6.preheader.i.i.i.i.i ], [ 0, %bb2.i.i.i.i.i ], [ 0, %bb10.i.i.i.i.i ]
  %_0.sroa.4.1.i.i.i = phi i64 [ %found_char.i.i.i.i, %bb31.i.i.i.i ], [ 23, %bb4.i.i.i.i ], [ 23, %bb6.preheader.i.i.i.i.i ], [ 23, %bb2.i.i.i.i.i ], [ 23, %bb10.i.i.i.i.i ]
; call __rustc::__rust_no_alloc_shim_is_unstable_v2
  tail call void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() #13, !noalias !98
; call __rustc::__rust_alloc
  %10 = tail call noundef align 8 dereferenceable_or_null(64) ptr @_RNvCs5fGHjzWXRav_7___rustc12___rust_alloc(i64 noundef range(i64 0, -9223372036854775808) 64, i64 noundef range(i64 1, 9) 8) #13, !noalias !98
  %11 = icmp eq ptr %10, null
  br i1 %11, label %bb3.i.i, label %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i

bb3.i.i:                                          ; preds = %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i
; call alloc::raw_vec::handle_error
  tail call void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef 8, i64 64) #14, !noalias !83
  unreachable

_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i: ; preds = %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i
  store ptr @alloc_e342eacdbf38ee6e7c7878ca690b4e0f, ptr %10, align 8, !noalias !83, !captures !101
  %12 = getelementptr inbounds nuw i8, ptr %10, i64 8
  store i64 %_0.sroa.4.1.i.i.i, ptr %12, align 8, !noalias !83
  store i64 4, ptr %vector.i, align 8, !noalias !83
  %vector1.sroa.4.0.vector.sroa_idx.i = getelementptr inbounds nuw i8, ptr %vector.i, i64 8
  store ptr %10, ptr %vector1.sroa.4.0.vector.sroa_idx.i, align 8, !noalias !83
  %vector1.sroa.6.0.vector.sroa_idx.i = getelementptr inbounds nuw i8, ptr %vector.i, i64 16
  store i64 1, ptr %vector1.sroa.6.0.vector.sroa_idx.i, align 8, !noalias !83
  call void @llvm.lifetime.start.p0(ptr nonnull %_19.i), !noalias !83
  store i64 %_2.sroa.0.0, ptr %_19.i, align 8, !noalias !102
  %_2.sroa.5.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 8
  store i64 23, ptr %_2.sroa.5.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.6.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 16
  store ptr @alloc_e342eacdbf38ee6e7c7878ca690b4e0f, ptr %_2.sroa.6.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.7.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 24
  store i64 23, ptr %_2.sroa.7.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.8.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 32
  store i64 %_2.sroa.8.0, ptr %_2.sroa.8.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.10.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 40
  store i64 23, ptr %_2.sroa.10.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.11.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 48
  store i32 44, ptr %_2.sroa.11.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.13.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 52
  store i32 44, ptr %_2.sroa.13.0._19.i.sroa_idx, align 4, !noalias !102
  %_2.sroa.14.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 56
  store i8 1, ptr %_2.sroa.14.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.1556.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 64
  store i8 1, ptr %_2.sroa.1556.0._19.i.sroa_idx, align 8, !noalias !102
  %_2.sroa.16.0._19.i.sroa_idx = getelementptr inbounds nuw i8, ptr %_19.i, i64 65
  store i8 %_2.sroa.16.0, ptr %_2.sroa.16.0._19.i.sroa_idx, align 1, !noalias !102
  tail call void @llvm.experimental.noalias.scope.decl(metadata !103)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !106)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !108)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !111)
  %13 = getelementptr inbounds nuw i8, ptr %_19.i, i64 65
  %_2.i.i11.i.i.i = trunc nuw i8 %_2.sroa.16.0 to i1
  br i1 %_2.i.i11.i.i.i, label %bb6.preheader, label %bb2.i.i.lr.ph.i.i.i

bb2.i.i.lr.ph.i.i.i:                              ; preds = %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i
  %iterator.promoted.i.i.i = load i64, ptr %_19.i, align 8, !alias.scope !113, !noalias !114
  %_4.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_19.i, i64 16
  %_0.0.i.i.i.i.i.i = load ptr, ptr %_4.i.i.i.i.i, align 8, !alias.scope !115, !noalias !114, !nonnull !10, !noundef !10
  %14 = getelementptr inbounds nuw i8, ptr %_19.i, i64 24
  %_0.1.i.i.i.i.i.i = load i64, ptr %14, align 8, !alias.scope !115, !noalias !114, !noundef !10
  %15 = getelementptr inbounds nuw i8, ptr %_19.i, i64 32
  %16 = getelementptr inbounds nuw i8, ptr %_19.i, i64 40
  %index2.i.i.i.i.i.i = load i64, ptr %16, align 8, !alias.scope !122, !noalias !125, !noundef !10
  %_38.not.i.i.i.i.i.i = icmp ugt i64 %index2.i.i.i.i.i.i, %_0.1.i.i.i.i.i.i
  %_11.i.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_19.i, i64 48
  %17 = getelementptr inbounds nuw i8, ptr %_19.i, i64 56
  %_48.i.i.i.i.i.i = load i8, ptr %17, align 8, !alias.scope !113, !noalias !114
  %_13.i.i.i.i.i.i = zext nneg i8 %_48.i.i.i.i.i.i to i64
  %_53.i.i.i.i.i.i = icmp ult i8 %_48.i.i.i.i.i.i, 5
  %18 = getelementptr i8, ptr %_11.i.i.i.i.i.i, i64 %_13.i.i.i.i.i.i
  %_51.i.i.i.i.i.i = getelementptr i8, ptr %18, i64 -1
  %19 = getelementptr inbounds nuw i8, ptr %_19.i, i64 64
  %20 = load i8, ptr %19, align 8, !range !127, !alias.scope !113, !noalias !114
  %_3.i.i.i.i.i.i = trunc nuw i8 %20 to i1
  %.phi.trans.insert.i.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_19.i, i64 8
  %i1.pre.i.i.i.i.i.i = load i64, ptr %.phi.trans.insert.i.i.i.i.i.i, align 8, !alias.scope !113, !noalias !114
  %.promoted13.i.i.i = load i64, ptr %15, align 8, !alias.scope !122, !noalias !125
  br label %bb2.i.i.i.i4.i

bb2.i.i.i.i4.i:                                   ; preds = %bb8.i.i.i, %bb2.i.i.lr.ph.i.i.i
  %_23.i.i23.i = phi ptr [ %10, %bb2.i.i.lr.ph.i.i.i ], [ %_23.i.i.i, %bb8.i.i.i ]
  %len.i.i.i = phi i64 [ 1, %bb2.i.i.lr.ph.i.i.i ], [ %new_len.i.i6.i, %bb8.i.i.i ]
  %21 = phi i64 [ %.promoted13.i.i.i, %bb2.i.i.lr.ph.i.i.i ], [ %31, %bb8.i.i.i ]
  %.lcssa1012.i.i.i = phi i64 [ %iterator.promoted.i.i.i, %bb2.i.i.lr.ph.i.i.i ], [ %.lcssa9.i.i.i, %bb8.i.i.i ]
  tail call void @llvm.experimental.noalias.scope.decl(metadata !128)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !129)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !130)
  %_4324.i.i.i.i.i.i = icmp ult i64 %index2.i.i.i.i.i.i, %21
  %or.cond25.i.i.i.i.i.i = or i1 %_38.not.i.i.i.i.i.i, %_4324.i.i.i.i.i.i
  br i1 %or.cond25.i.i.i.i.i.i, label %bb1.i.i.i.i.i.i, label %bb14.lr.ph.i.i.i.i.i.i

bb14.lr.ph.i.i.i.i.i.i:                           ; preds = %bb2.i.i.i.i4.i
  tail call void @llvm.assume(i1 %_53.i.i.i.i.i.i)
  %last_byte.pre.i.i.i.i.i.i = load i8, ptr %_51.i.i.i.i.i.i, align 1, !alias.scope !122, !noalias !125
  br label %bb14.i.i.i.i.i.i

bb14.i.i.i.i.i.i:                                 ; preds = %bb10.i.i.i.i.i.i, %bb14.lr.ph.i.i.i.i.i.i
  %22 = phi i64 [ %21, %bb14.lr.ph.i.i.i.i.i.i ], [ %29, %bb10.i.i.i.i.i.i ]
  %new_len.i.i.i.i.i.i = sub nuw i64 %index2.i.i.i.i.i.i, %22
  %_46.i.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_0.0.i.i.i.i.i.i, i64 %22
  %_3.i.i.i.i.i.i.i = icmp samesign ult i64 %new_len.i.i.i.i.i.i, 16
  br i1 %_3.i.i.i.i.i.i.i, label %bb6.preheader.i.i.i.i.i.i.i, label %bb2.i.i.i.i.i.i.i

bb6.preheader.i.i.i.i.i.i.i:                      ; preds = %bb14.i.i.i.i.i.i
  %_98.not.i.i.i.i.i.i.i = icmp eq i64 %index2.i.i.i.i.i.i, %22
  br i1 %_98.not.i.i.i.i.i.i.i, label %bb1.i.i.i.i.i.i, label %bb8.i.i.i.i.i.i.i

bb2.i.i.i.i.i.i.i:                                ; preds = %bb14.i.i.i.i.i.i
; call core::slice::memchr::memchr_aligned
  %23 = tail call { i64, i64 } @_RNvNtNtCskADBYZwJmSU_4core5slice6memchr14memchr_aligned(i8 noundef %last_byte.pre.i.i.i.i.i.i, ptr noalias nofree noundef nonnull readonly captures(address, read_provenance) %_46.i.i.i.i.i.i, i64 noundef range(i64 0, -9223372036854775808) %new_len.i.i.i.i.i.i) #13, !noalias !131
  %24 = extractvalue { i64, i64 } %23, 0
  %25 = extractvalue { i64, i64 } %23, 1
  %26 = trunc nuw i64 %24 to i1
  br i1 %26, label %bb4.i.i.i.i.i.i, label %bb1.i.i.i.i.i.i

bb8.i.i.i.i.i.i.i:                                ; preds = %bb6.preheader.i.i.i.i.i.i.i, %bb10.i.i.i.i.i.i.i
  %i.sroa.0.09.i.i.i.i.i.i.i = phi i64 [ %28, %bb10.i.i.i.i.i.i.i ], [ 0, %bb6.preheader.i.i.i.i.i.i.i ]
  %27 = getelementptr inbounds nuw i8, ptr %_46.i.i.i.i.i.i, i64 %i.sroa.0.09.i.i.i.i.i.i.i
  %_12.i.i.i.i.i.i.i = load i8, ptr %27, align 1, !alias.scope !132, !noalias !131, !noundef !10
  %_11.i.i.i.i.i.i.i = icmp eq i8 %_12.i.i.i.i.i.i.i, %last_byte.pre.i.i.i.i.i.i
  br i1 %_11.i.i.i.i.i.i.i, label %bb4.i.i.i.i.i.i, label %bb10.i.i.i.i.i.i.i

bb10.i.i.i.i.i.i.i:                               ; preds = %bb8.i.i.i.i.i.i.i
  %28 = add nuw nsw i64 %i.sroa.0.09.i.i.i.i.i.i.i, 1
  %exitcond.not.i.i.i.i.i.i.i = icmp eq i64 %28, %new_len.i.i.i.i.i.i
  br i1 %exitcond.not.i.i.i.i.i.i.i, label %bb1.i.i.i.i.i.i, label %bb8.i.i.i.i.i.i.i

bb4.i.i.i.i.i.i:                                  ; preds = %bb8.i.i.i.i.i.i.i, %bb2.i.i.i.i.i.i.i
  %result.sroa.5.0.i.i.i.i.i.i.i = phi i64 [ %25, %bb2.i.i.i.i.i.i.i ], [ %i.sroa.0.09.i.i.i.i.i.i.i, %bb8.i.i.i.i.i.i.i ]
  %cond.i.i.i.i.i.i.i = icmp ult i64 %result.sroa.5.0.i.i.i.i.i.i.i, %new_len.i.i.i.i.i.i
  tail call void @llvm.assume(i1 %cond.i.i.i.i.i.i.i)
  %_17.i.i.i.i.i.i = add i64 %22, 1
  %29 = add i64 %_17.i.i.i.i.i.i, %result.sroa.5.0.i.i.i.i.i.i.i
  %_18.not.i.i.i.i.i.i = icmp ult i64 %29, %_13.i.i.i.i.i.i
  %_56.not.i.i.i.i.i.i = icmp ugt i64 %29, %_0.1.i.i.i.i.i.i
  %or.cond.i.i.i.i.i.i = or i1 %_18.not.i.i.i.i.i.i, %_56.not.i.i.i.i.i.i
  br i1 %or.cond.i.i.i.i.i.i, label %bb10.i.i.i.i.i.i, label %bb31.i.i.i.i.i.i

bb10.i.i.i.i.i.i:                                 ; preds = %bb31.i.i.i.i.i.i, %bb4.i.i.i.i.i.i
  %_43.i.i.i.i.i.i = icmp ult i64 %index2.i.i.i.i.i.i, %29
  br i1 %_43.i.i.i.i.i.i, label %bb1.i.i.i.i.i.i, label %bb14.i.i.i.i.i.i

bb31.i.i.i.i.i.i:                                 ; preds = %bb4.i.i.i.i.i.i
  %found_char.i.i.i.i.i.i = sub nuw i64 %29, %_13.i.i.i.i.i.i
  %_64.i.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_0.0.i.i.i.i.i.i, i64 %found_char.i.i.i.i.i.i
  %bcmp.i.i.i.i.i.i = call i32 @bcmp(ptr nonnull %_64.i.i.i.i.i.i, ptr nonnull %_11.i.i.i.i.i.i, i64 %_13.i.i.i.i.i.i), !noalias !125
  %_28.i.i.i.i.i.i = icmp eq i32 %bcmp.i.i.i.i.i.i, 0
  br i1 %_28.i.i.i.i.i.i, label %bb3.i.i.i, label %bb10.i.i.i.i.i.i

bb1.i.i.i.i.i.i:                                  ; preds = %bb10.i.i.i.i.i.i, %bb2.i.i.i.i.i.i.i, %bb6.preheader.i.i.i.i.i.i.i, %bb10.i.i.i.i.i.i.i, %bb2.i.i.i.i4.i
  %30 = phi i64 [ %21, %bb2.i.i.i.i4.i ], [ %index2.i.i.i.i.i.i, %bb10.i.i.i.i.i.i.i ], [ %index2.i.i.i.i.i.i, %bb6.preheader.i.i.i.i.i.i.i ], [ %index2.i.i.i.i.i.i, %bb2.i.i.i.i.i.i.i ], [ %29, %bb10.i.i.i.i.i.i ]
  store i8 1, ptr %13, align 1, !alias.scope !135, !noalias !114
  %_4.not.i.i.i.i.i.i = icmp ne i64 %i1.pre.i.i.i.i.i.i, %.lcssa1012.i.i.i
  %or.cond.not.i.i.i.i.i.i = select i1 %_3.i.i.i.i.i.i, i1 true, i1 %_4.not.i.i.i.i.i.i
  br i1 %or.cond.not.i.i.i.i.i.i, label %bb3.i.i.i, label %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit

bb3.i.i.i:                                        ; preds = %bb31.i.i.i.i.i.i, %bb1.i.i.i.i.i.i
  %31 = phi i64 [ %30, %bb1.i.i.i.i.i.i ], [ %29, %bb31.i.i.i.i.i.i ]
  %.lcssa9.i.i.i = phi i64 [ %.lcssa1012.i.i.i, %bb1.i.i.i.i.i.i ], [ %29, %bb31.i.i.i.i.i.i ]
  %_2.i.i.i.i.i = phi i1 [ true, %bb1.i.i.i.i.i.i ], [ false, %bb31.i.i.i.i.i.i ]
  %found_char.i.i.i.pn.i.i.i = phi i64 [ %i1.pre.i.i.i.i.i.i, %bb1.i.i.i.i.i.i ], [ %found_char.i.i.i.i.i.i, %bb31.i.i.i.i.i.i ]
  %_0.sroa.4.1.i.i.i.i.i = sub nuw i64 %found_char.i.i.i.pn.i.i.i, %.lcssa1012.i.i.i
  %_0.sroa.0.1.i.i.i.i.i = getelementptr inbounds nuw i8, ptr %_0.0.i.i.i.i.i.i, i64 %.lcssa1012.i.i.i
  %_19.i.i.i = icmp samesign ult i64 %len.i.i.i, 576460752303423488
  tail call void @llvm.assume(i1 %_19.i.i.i)
  %self1.i.i5.i = load i64, ptr %vector.i, align 8, !range !9, !alias.scope !138, !noalias !139, !noundef !10
  %_8.i.i.i = icmp eq i64 %len.i.i.i, %self1.i.i5.i
  br i1 %_8.i.i.i, label %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VecReE7reserveCsYR6quqRMAk_6tier_b.exit.i.i.i, label %bb8.i.i.i

_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VecReE7reserveCsYR6quqRMAk_6tier_b.exit.i.i.i: ; preds = %bb3.i.i.i
; call <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
  call fastcc void @_RINvNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecINtB8_11RawVecInnerpE7reserve21do_reserve_and_handleNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %vector.i, i64 noundef %len.i.i.i, i64 noundef range(i64 1, 0) 1, i64 noundef 8, i64 noundef 16) #13, !noalias !139
  %_23.i.i.pre.i = load ptr, ptr %vector1.sroa.4.0.vector.sroa_idx.i, align 8, !alias.scope !138, !noalias !139
  br label %bb8.i.i.i

bb8.i.i.i:                                        ; preds = %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VecReE7reserveCsYR6quqRMAk_6tier_b.exit.i.i.i, %bb3.i.i.i
  %_23.i.i.i = phi ptr [ %_23.i.i.pre.i, %_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VecReE7reserveCsYR6quqRMAk_6tier_b.exit.i.i.i ], [ %_23.i.i23.i, %bb3.i.i.i ]
  %dst.i.i.i = getelementptr inbounds nuw [16 x i8], ptr %_23.i.i.i, i64 %len.i.i.i
  store ptr %_0.sroa.0.1.i.i.i.i.i, ptr %dst.i.i.i, align 8, !noalias !140, !captures !101
  %32 = getelementptr inbounds nuw i8, ptr %dst.i.i.i, i64 8
  store i64 %_0.sroa.4.1.i.i.i.i.i, ptr %32, align 8, !noalias !140
  %new_len.i.i6.i = add nuw nsw i64 %len.i.i.i, 1
  store i64 %new_len.i.i6.i, ptr %vector1.sroa.6.0.vector.sroa_idx.i, align 8, !alias.scope !138, !noalias !139
  br i1 %_2.i.i.i.i.i, label %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit, label %bb2.i.i.i.i4.i

_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit: ; preds = %bb8.i.i.i, %bb1.i.i.i.i.i.i
  %parts.sroa.8.0.copyload24 = phi i64 [ %new_len.i.i6.i, %bb8.i.i.i ], [ %len.i.i.i, %bb1.i.i.i.i.i.i ]
  %parts.sroa.0.0.copyload.pre = load i64, ptr %vector.i, align 8, !noalias !141
  %parts.sroa.5.0.copyload.pre = load ptr, ptr %vector1.sroa.4.0.vector.sroa_idx.i, align 8, !noalias !141
  br label %bb6.preheader

bb6.preheader:                                    ; preds = %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i, %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit
  %parts.sroa.8.0.copyload = phi i64 [ %parts.sroa.8.0.copyload24, %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit ], [ 1, %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i ]
  %parts.sroa.5.0.copyload = phi ptr [ %parts.sroa.5.0.copyload.pre, %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit ], [ %10, %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i ]
  %parts.sroa.0.0.copyload = phi i64 [ %parts.sroa.0.0.copyload.pre, %_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b.exit.loopexit ], [ 4, %_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner16with_capacity_inCsYR6quqRMAk_6tier_b.exit.i ]
  call void @llvm.lifetime.end.p0(ptr nonnull %_19.i), !noalias !83
  call void @llvm.lifetime.end.p0(ptr nonnull %vector.i), !noalias !83
  %33 = add nsw i64 %parts.sroa.8.0.copyload, 1152921504606846975
  %34 = and i64 %33, 1152921504606846975
  %35 = add nuw nsw i64 %34, 1
  %xtraiter = and i64 %35, 7
  %36 = icmp samesign ult i64 %34, 7
  br i1 %36, label %bb6.epil.preheader, label %bb6.preheader.new

bb6.preheader.new:                                ; preds = %bb6.preheader
  %unroll_iter = and i64 %35, 2305843009213693944
  br label %bb6

bb6:                                              ; preds = %bb6, %bb6.preheader.new
  %total.sroa.0.015 = phi i64 [ 0, %bb6.preheader.new ], [ %52, %bb6 ]
  %iter.sroa.0.014 = phi ptr [ %parts.sroa.5.0.copyload, %bb6.preheader.new ], [ %_36.7, %bb6 ]
  %niter = phi i64 [ 0, %bb6.preheader.new ], [ %niter.next.7, %bb6 ]
  %37 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 8
  %_12.1 = load i64, ptr %37, align 8, !noundef !10
  %38 = add i64 %_12.1, %total.sroa.0.015
  %39 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 24
  %_12.1.1 = load i64, ptr %39, align 8, !noundef !10
  %40 = add i64 %_12.1.1, %38
  %41 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 40
  %_12.1.2 = load i64, ptr %41, align 8, !noundef !10
  %42 = add i64 %_12.1.2, %40
  %43 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 56
  %_12.1.3 = load i64, ptr %43, align 8, !noundef !10
  %44 = add i64 %_12.1.3, %42
  %45 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 72
  %_12.1.4 = load i64, ptr %45, align 8, !noundef !10
  %46 = add i64 %_12.1.4, %44
  %47 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 88
  %_12.1.5 = load i64, ptr %47, align 8, !noundef !10
  %48 = add i64 %_12.1.5, %46
  %49 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 104
  %_12.1.6 = load i64, ptr %49, align 8, !noundef !10
  %50 = add i64 %_12.1.6, %48
  %_36.7 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 128
  %51 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014, i64 120
  %_12.1.7 = load i64, ptr %51, align 8, !noundef !10
  %52 = add i64 %_12.1.7, %50
  %niter.next.7 = add i64 %niter, 8
  %niter.ncmp.7 = icmp eq i64 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %bb5.unr-lcssa, label %bb6

bb5.unr-lcssa:                                    ; preds = %bb6
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod.not, label %bb5, label %bb6.epil.preheader

bb6.epil.preheader:                               ; preds = %bb5.unr-lcssa, %bb6.preheader
  %total.sroa.0.015.epil.init = phi i64 [ 0, %bb6.preheader ], [ %52, %bb5.unr-lcssa ]
  %iter.sroa.0.014.epil.init = phi ptr [ %parts.sroa.5.0.copyload, %bb6.preheader ], [ %_36.7, %bb5.unr-lcssa ]
  %lcmp.mod55 = icmp ne i64 %xtraiter, 0
  tail call void @llvm.assume(i1 %lcmp.mod55)
  br label %bb6.epil

bb6.epil:                                         ; preds = %bb6.epil, %bb6.epil.preheader
  %total.sroa.0.015.epil = phi i64 [ %54, %bb6.epil ], [ %total.sroa.0.015.epil.init, %bb6.epil.preheader ]
  %iter.sroa.0.014.epil = phi ptr [ %_36.epil, %bb6.epil ], [ %iter.sroa.0.014.epil.init, %bb6.epil.preheader ]
  %epil.iter = phi i64 [ %epil.iter.next, %bb6.epil ], [ 0, %bb6.epil.preheader ]
  %_36.epil = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014.epil, i64 16
  %53 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.014.epil, i64 8
  %_12.1.epil = load i64, ptr %53, align 8, !noundef !10
  %54 = add i64 %_12.1.epil, %total.sroa.0.015.epil
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %bb5, label %bb6.epil, !llvm.loop !142

bb5:                                              ; preds = %bb6.epil, %bb5.unr-lcssa
  %.lcssa = phi i64 [ %52, %bb5.unr-lcssa ], [ %54, %bb6.epil ]
  %_39 = icmp ult i64 %parts.sroa.8.0.copyload, 576460752303423488
  tail call void @llvm.assume(i1 %_39)
  %55 = icmp eq i64 %parts.sroa.0.0.copyload, 0
  br i1 %55, label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecReEECsYR6quqRMAk_6tier_b.exit, label %bb2.i.i.i.i

bb2.i.i.i.i:                                      ; preds = %bb5
  %alloc_size.i.i.i.i.i = shl nuw i64 %parts.sroa.0.0.copyload, 4
; call __rustc::__rust_dealloc
  tail call void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr noundef nonnull %parts.sroa.5.0.copyload, i64 noundef %alloc_size.i.i.i.i.i, i64 noundef range(i64 1, -9223372036854775807) 8) #13, !noalias !143
  br label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecReEECsYR6quqRMAk_6tier_b.exit

_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecReEECsYR6quqRMAk_6tier_b.exit: ; preds = %bb5, %bb2.i.i.i.i
  %_9 = mul i64 %parts.sroa.8.0.copyload, 100
  %_0 = add i64 %.lcssa, %_9
  ret i64 %_0
}

; Function Attrs: nounwind nonlazybind uwtable
define noundef i64 @vec_filter_sum(i32 noundef %n) unnamed_addr #2 personality ptr @rust_eh_personality !guid !152 {
start:
  %_4 = zext i32 %n to i64
  %0 = shl nuw nsw i64 %_4, 3
  %1 = icmp eq i32 %n, 0
  br i1 %1, label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit, label %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i

_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i: ; preds = %start
; call __rustc::__rust_no_alloc_shim_is_unstable_v2
  tail call void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() #13, !noalias !153
; call __rustc::__rust_alloc
  %2 = tail call noundef align 8 ptr @_RNvCs5fGHjzWXRav_7___rustc12___rust_alloc(i64 noundef range(i64 0, -9223372036854775808) %0, i64 noundef range(i64 1, 9) 8) #13, !noalias !153
  %3 = icmp eq ptr %2, null
  br i1 %3, label %bb3.i.i, label %bb3.i.i.i.i.i.preheader

bb3.i.i.i.i.i.preheader:                          ; preds = %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i
  %min.iters.check = icmp ult i32 %n, 4
  br i1 %min.iters.check, label %bb3.i.i.i.i.i.preheader6, label %vector.ph

vector.ph:                                        ; preds = %bb3.i.i.i.i.i.preheader
  %n.vec = and i64 %_4, 4294967292
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.ind = phi <2 x i64> [ <i64 0, i64 1>, %vector.ph ], [ %vec.ind.next, %vector.body ]
  %step.add = add nuw <2 x i64> %vec.ind, splat (i64 2)
  %4 = getelementptr inbounds nuw [8 x i8], ptr %2, i64 %index
  %5 = getelementptr inbounds nuw i8, ptr %4, i64 16
  store <2 x i64> %vec.ind, ptr %4, align 8, !noalias !158
  store <2 x i64> %step.add, ptr %5, align 8, !noalias !158
  %index.next = add nuw i64 %index, 4
  %vec.ind.next = add nuw <2 x i64> %vec.ind, splat (i64 4)
  %6 = icmp eq i64 %index.next, %n.vec
  br i1 %6, label %middle.block, label %vector.body, !llvm.loop !171

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n.vec, %_4
  br i1 %cmp.n, label %bb8.i.preheader, label %bb3.i.i.i.i.i.preheader6

bb3.i.i.i.i.i.preheader6:                         ; preds = %bb3.i.i.i.i.i.preheader, %middle.block
  %.ph = phi i64 [ 0, %bb3.i.i.i.i.i.preheader ], [ %n.vec, %middle.block ]
  br label %bb3.i.i.i.i.i

bb3.i.i:                                          ; preds = %_RNvXs1_NtCsgFX3jaOk65H_5alloc5allocNtB5_6GlobalNtNtCskADBYZwJmSU_4core5alloc9Allocator8allocate.exit.i.i.i
; call alloc::raw_vec::handle_error
  tail call void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef 8, i64 %0) #14, !noalias !174
  unreachable

bb3.i.i.i.i.i:                                    ; preds = %bb3.i.i.i.i.i.preheader6, %bb3.i.i.i.i.i
  %7 = phi i64 [ %8, %bb3.i.i.i.i.i ], [ %.ph, %bb3.i.i.i.i.i.preheader6 ]
  %8 = add nuw nsw i64 %7, 1
  %_3.i.i.i.i.i.i.i = getelementptr inbounds nuw [8 x i8], ptr %2, i64 %7
  store i64 %7, ptr %_3.i.i.i.i.i.i.i, align 8, !noalias !158
  %exitcond.not.i.i.i.i.i = icmp eq i64 %8, %_4
  br i1 %exitcond.not.i.i.i.i.i, label %bb8.i.preheader, label %bb3.i.i.i.i.i, !llvm.loop !175

bb8.i.preheader:                                  ; preds = %bb3.i.i.i.i.i, %middle.block
  %xtraiter = and i64 %_4, 1
  %9 = icmp eq i32 %n, 1
  br i1 %9, label %bb8.i.epil.preheader, label %bb8.i.preheader.new

bb8.i.preheader.new:                              ; preds = %bb8.i.preheader
  %unroll_iter = and i64 %_4, 4294967294
  br label %bb8.i

bb8.i:                                            ; preds = %bb8.i, %bb8.i.preheader.new
  %i.sroa.0.0.i = phi i64 [ 0, %bb8.i.preheader.new ], [ %_27.i.1, %bb8.i ]
  %acc.sroa.0.0.i = phi i64 [ 0, %bb8.i.preheader.new ], [ %_0.sroa.0.0.i.i.1, %bb8.i ]
  %niter = phi i64 [ 0, %bb8.i.preheader.new ], [ %niter.next.1, %bb8.i ]
  %_45.i = getelementptr inbounds nuw [8 x i8], ptr %2, i64 %i.sroa.0.0.i
  %_4.i.i.i = load i64, ptr %_45.i, align 8, !alias.scope !176, !noalias !179, !noundef !10
  %_3.i.i.i = and i64 %_4.i.i.i, 1
  %_0.i.i.i = icmp eq i64 %_3.i.i.i, 0
  %_4.0.i.i.i.i = add i64 %acc.sroa.0.0.i, 1
  %_4.0.i1.i.i.i = add i64 %_4.0.i.i.i.i, %_4.i.i.i
  %_0.sroa.0.0.i.i = select i1 %_0.i.i.i, i64 %_4.0.i1.i.i.i, i64 %acc.sroa.0.0.i
  %10 = getelementptr inbounds nuw [8 x i8], ptr %2, i64 %i.sroa.0.0.i
  %_45.i.1 = getelementptr inbounds nuw i8, ptr %10, i64 8
  %_4.i.i.i.1 = load i64, ptr %_45.i.1, align 8, !alias.scope !176, !noalias !179, !noundef !10
  %_3.i.i.i.1 = and i64 %_4.i.i.i.1, 1
  %_0.i.i.i.1 = icmp eq i64 %_3.i.i.i.1, 0
  %_4.0.i.i.i.i.1 = add i64 %_0.sroa.0.0.i.i, 1
  %_4.0.i1.i.i.i.1 = add i64 %_4.0.i.i.i.i.1, %_4.i.i.i.1
  %_0.sroa.0.0.i.i.1 = select i1 %_0.i.i.i.1, i64 %_4.0.i1.i.i.i.1, i64 %_0.sroa.0.0.i.i
  %_27.i.1 = add nuw nsw i64 %i.sroa.0.0.i, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %bb2.i.i.i.i.unr-lcssa, label %bb8.i

bb2.i.i.i.i.unr-lcssa:                            ; preds = %bb8.i
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod.not, label %bb2.i.i.i.i, label %bb8.i.epil.preheader

bb8.i.epil.preheader:                             ; preds = %bb2.i.i.i.i.unr-lcssa, %bb8.i.preheader
  %i.sroa.0.0.i.epil.init = phi i64 [ 0, %bb8.i.preheader ], [ %_27.i.1, %bb2.i.i.i.i.unr-lcssa ]
  %acc.sroa.0.0.i.epil.init = phi i64 [ 0, %bb8.i.preheader ], [ %_0.sroa.0.0.i.i.1, %bb2.i.i.i.i.unr-lcssa ]
  %lcmp.mod8 = trunc i32 %n to i1
  tail call void @llvm.assume(i1 %lcmp.mod8)
  %_45.i.epil = getelementptr inbounds nuw [8 x i8], ptr %2, i64 %i.sroa.0.0.i.epil.init
  %_4.i.i.i.epil = load i64, ptr %_45.i.epil, align 8, !alias.scope !176, !noalias !179, !noundef !10
  %_3.i.i.i.epil = and i64 %_4.i.i.i.epil, 1
  %_0.i.i.i.epil = icmp eq i64 %_3.i.i.i.epil, 0
  %_4.0.i.i.i.i.epil = add i64 %acc.sroa.0.0.i.epil.init, 1
  %_4.0.i1.i.i.i.epil = add i64 %_4.0.i.i.i.i.epil, %_4.i.i.i.epil
  %_0.sroa.0.0.i.i.epil = select i1 %_0.i.i.i.epil, i64 %_4.0.i1.i.i.i.epil, i64 %acc.sroa.0.0.i.epil.init
  br label %bb2.i.i.i.i

bb2.i.i.i.i:                                      ; preds = %bb2.i.i.i.i.unr-lcssa, %bb8.i.epil.preheader
  %_0.sroa.0.0.i.i.lcssa = phi i64 [ %_0.sroa.0.0.i.i.1, %bb2.i.i.i.i.unr-lcssa ], [ %_0.sroa.0.0.i.i.epil, %bb8.i.epil.preheader ]
; call __rustc::__rust_dealloc
  tail call void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr noundef nonnull %2, i64 noundef %0, i64 noundef range(i64 1, -9223372036854775807) 8) #13, !noalias !182
  br label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit

_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit: ; preds = %start, %bb2.i.i.i.i
  %_0.sroa.0.0.i5 = phi i64 [ %_0.sroa.0.0.i.i.lcssa, %bb2.i.i.i.i ], [ 0, %start ]
  ret i64 %_0.sroa.0.0.i5
}

; Function Attrs: nounwind nonlazybind uwtable
define noundef i64 @vec_sum(i32 noundef %n) unnamed_addr #2 personality ptr @rust_eh_personality !guid !191 {
start:
  %v = alloca [24 x i8], align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %v)
  store i64 0, ptr %v, align 8
  %0 = getelementptr inbounds nuw i8, ptr %v, i64 8
  store ptr inttoptr (i64 8 to ptr), ptr %0, align 8
  %1 = getelementptr inbounds nuw i8, ptr %v, i64 16
  store i64 0, ptr %1, align 8
  %_6 = zext i32 %n to i64
  %_45.not = icmp eq i32 %n, 0
  br i1 %_45.not, label %bb7, label %bb2

bb3:                                              ; preds = %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit
  %_18.pre = load ptr, ptr %0, align 8
  %_22.idx = shl nuw nsw i64 %13, 3
  %_22 = getelementptr inbounds nuw i8, ptr %_18.pre, i64 %_22.idx
  %_287 = icmp eq i64 %13, 0
  br i1 %_287, label %bb7, label %bb8.preheader

bb8.preheader:                                    ; preds = %bb3
  %2 = add nuw nsw i64 %_6, 2305843009213693951
  %3 = and i64 %2, 2305843009213693951
  %4 = add nuw nsw i64 %3, 1
  %min.iters.check = icmp samesign ult i64 %3, 3
  br i1 %min.iters.check, label %bb8.preheader26, label %vector.ph

vector.ph:                                        ; preds = %bb8.preheader
  %n.vec = and i64 %4, 4611686018427387900
  %5 = shl i64 %n.vec, 3
  %6 = getelementptr i8, ptr %_18.pre, i64 %5
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.phi = phi <2 x i64> [ zeroinitializer, %vector.ph ], [ %9, %vector.body ]
  %vec.phi24 = phi <2 x i64> [ zeroinitializer, %vector.ph ], [ %10, %vector.body ]
  %7 = shl i64 %index, 3
  %next.gep = getelementptr i8, ptr %_18.pre, i64 %7
  %8 = getelementptr i8, ptr %next.gep, i64 16
  %wide.load = load <2 x i64>, ptr %next.gep, align 8
  %wide.load25 = load <2 x i64>, ptr %8, align 8
  %9 = add <2 x i64> %wide.load, %vec.phi
  %10 = add <2 x i64> %wide.load25, %vec.phi24
  %index.next = add nuw i64 %index, 4
  %11 = icmp eq i64 %index.next, %n.vec
  br i1 %11, label %middle.block, label %vector.body, !llvm.loop !192

middle.block:                                     ; preds = %vector.body
  %bin.rdx = add <2 x i64> %10, %9
  %12 = tail call i64 @llvm.vector.reduce.add.v2i64(<2 x i64> %bin.rdx)
  %cmp.n = icmp eq i64 %4, %n.vec
  br i1 %cmp.n, label %bb7, label %bb8.preheader26

bb8.preheader26:                                  ; preds = %bb8.preheader, %middle.block
  %s.sroa.0.09.ph = phi i64 [ 0, %bb8.preheader ], [ %12, %middle.block ]
  %iter.sroa.0.08.ph = phi ptr [ %_18.pre, %bb8.preheader ], [ %6, %middle.block ]
  br label %bb8

bb2:                                              ; preds = %start, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit
  %_14.i14 = phi ptr [ %_14.i, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ inttoptr (i64 8 to ptr), %start ]
  %self1.i = phi i64 [ %self1.i12, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %len.i = phi i64 [ %13, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %i.sroa.0.06 = phi i64 [ %14, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %_8 = mul nuw i64 %i.sroa.0.06, %i.sroa.0.06
  tail call void @llvm.experimental.noalias.scope.decl(metadata !193)
  %_4.i = icmp eq i64 %len.i, %self1.i
  br i1 %_4.i, label %bb1.i, label %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit

bb1.i:                                            ; preds = %bb2
; call <alloc::raw_vec::RawVec<u64>>::grow_one
  call void @_RNvMs4_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyE8grow_oneCsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %v) #15
  %self1.i.pre = load i64, ptr %v, align 8, !range !9, !alias.scope !193
  %_14.i.pre = load ptr, ptr %0, align 8, !alias.scope !193
  br label %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit

_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit: ; preds = %bb2, %bb1.i
  %_14.i = phi ptr [ %_14.i14, %bb2 ], [ %_14.i.pre, %bb1.i ]
  %self1.i12 = phi i64 [ %self1.i, %bb2 ], [ %self1.i.pre, %bb1.i ]
  %end.i = getelementptr inbounds nuw [8 x i8], ptr %_14.i, i64 %len.i
  store i64 %_8, ptr %end.i, align 8, !noalias !193
  %13 = add i64 %len.i, 1
  store i64 %13, ptr %1, align 8, !alias.scope !193
  %14 = add nuw nsw i64 %i.sroa.0.06, 1
  %exitcond.not = icmp eq i64 %14, %_6
  br i1 %exitcond.not, label %bb3, label %bb2

bb8:                                              ; preds = %bb8.preheader26, %bb8
  %s.sroa.0.09 = phi i64 [ %_37.0, %bb8 ], [ %s.sroa.0.09.ph, %bb8.preheader26 ]
  %iter.sroa.0.08 = phi ptr [ %_34, %bb8 ], [ %iter.sroa.0.08.ph, %bb8.preheader26 ]
  %_34 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 8
  %_36 = load i64, ptr %iter.sroa.0.08, align 8, !noundef !10
  %_37.0 = add i64 %_36, %s.sroa.0.09
  %_28 = icmp eq ptr %_34, %_22
  br i1 %_28, label %bb7, label %bb8, !llvm.loop !196

bb7:                                              ; preds = %bb8, %middle.block, %start, %bb3
  %_1823 = phi ptr [ %_18.pre, %bb3 ], [ inttoptr (i64 8 to ptr), %start ], [ %_18.pre, %middle.block ], [ %_18.pre, %bb8 ]
  %s.sroa.0.0.lcssa = phi i64 [ 0, %bb3 ], [ 0, %start ], [ %12, %middle.block ], [ %_37.0, %bb8 ]
  tail call void @llvm.experimental.noalias.scope.decl(metadata !197)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !200)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !203)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !206)
  %self1.i.i.i.i.i = load i64, ptr %v, align 8, !range !9, !alias.scope !209, !noalias !212, !noundef !10
  %15 = icmp eq i64 %self1.i.i.i.i.i, 0
  br i1 %15, label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit, label %bb2.i.i.i.i

bb2.i.i.i.i:                                      ; preds = %bb7
  %alloc_size.i.i.i.i.i = shl nuw i64 %self1.i.i.i.i.i, 3
; call __rustc::__rust_dealloc
  tail call void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr noundef nonnull %_1823, i64 noundef %alloc_size.i.i.i.i.i, i64 noundef range(i64 1, -9223372036854775807) 8) #13, !noalias !214
  br label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit

_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit: ; preds = %bb7, %bb2.i.i.i.i
  call void @llvm.lifetime.end.p0(ptr nonnull %v)
  ret i64 %s.sroa.0.0.lcssa
}

; Function Attrs: nounwind nonlazybind uwtable
declare noundef range(i32 0, 10) i32 @rust_eh_personality(i32 noundef, i32 noundef, i64 noundef, ptr noundef, ptr noundef) unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #3

; alloc::raw_vec::handle_error
; Function Attrs: cold minsize noreturn nounwind nonlazybind optsize uwtable
declare void @_RNvNtCsgFX3jaOk65H_5alloc7raw_vec12handle_error(i64 noundef range(i64 0, -9223372036854775807), i64) unnamed_addr #5

; __rustc::__rust_dealloc
; Function Attrs: nounwind nonlazybind allockind("free") uwtable
declare void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr allocptr noundef nonnull captures(address), i64 noundef, i64 noundef range(i64 1, -9223372036854775807)) unnamed_addr #6

; __rustc::__rust_realloc
; Function Attrs: nounwind nonlazybind allockind("realloc,aligned") allocsize(3) uwtable
declare noalias noundef ptr @_RNvCs5fGHjzWXRav_7___rustc14___rust_realloc(ptr allocptr noundef nonnull, i64 noundef, i64 allocalign noundef range(i64 1, -9223372036854775807), i64 noundef) unnamed_addr #7

; __rustc::__rust_no_alloc_shim_is_unstable_v2
; Function Attrs: nounwind nonlazybind uwtable
declare void @_RNvCs5fGHjzWXRav_7___rustc35___rust_no_alloc_shim_is_unstable_v2() unnamed_addr #2

; __rustc::__rust_alloc
; Function Attrs: nounwind nonlazybind allockind("alloc,uninitialized,aligned") allocsize(0) uwtable
declare noalias noundef ptr @_RNvCs5fGHjzWXRav_7___rustc12___rust_alloc(i64 noundef, i64 allocalign noundef range(i64 1, -9223372036854775807)) unnamed_addr #8

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #9

; core::slice::memchr::memchr_aligned
; Function Attrs: nounwind nonlazybind uwtable
declare { i64, i64 } @_RNvNtNtCskADBYZwJmSU_4core5slice6memchr14memchr_aligned(i8 noundef, ptr noalias nofree noundef nonnull readonly captures(address, read_provenance), i64 noundef range(i64 0, -9223372036854775808)) unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind nonlazybind willreturn memory(argmem: read)
declare i32 @bcmp(ptr captures(none), ptr captures(none), i64) local_unnamed_addr #10

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare void @llvm.experimental.noalias.scope.decl(metadata) #11

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #12

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.vector.reduce.add.v2i64(<2 x i64>) #12

attributes #0 = { cold nounwind nonlazybind uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #1 = { cold noinline nounwind nonlazybind uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #2 = { nounwind nonlazybind uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #5 = { cold minsize noreturn nounwind nonlazybind optsize uwtable "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #6 = { nounwind nonlazybind allockind("free") uwtable "alloc-family"="__rust_alloc" "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #7 = { nounwind nonlazybind allockind("realloc,aligned") allocsize(3) uwtable "alloc-family"="__rust_alloc" "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #8 = { nounwind nonlazybind allockind("alloc,uninitialized,aligned") allocsize(0) uwtable "alloc-family"="__rust_alloc" "alloc-variant-zeroed"="_RNvCs5fGHjzWXRav_7___rustc19___rust_alloc_zeroed" "probe-stack"="inline-asm" "target-cpu"="x86-64" }
attributes #9 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #10 = { nocallback nofree nosync nounwind nonlazybind willreturn memory(argmem: read) }
attributes #11 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #12 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #13 = { nounwind }
attributes #14 = { noreturn nounwind }
attributes #15 = { noinline nounwind }

!llvm.module.flags = !{!1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i64 -782166233642507960}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 2, !"RtLibUseGOT", i32 1}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"rustc version 1.99.1 (58cf8f9c3 2026-10-13)"}
!5 = !{i64 -6555122703465490592}
!6 = !{!7}
!7 = distinct !{!7, !8, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14grow_amortizedCsYR6quqRMAk_6tier_b: %self"}
!8 = distinct !{!8, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14grow_amortizedCsYR6quqRMAk_6tier_b"}
!9 = !{i64 0, i64 -9223372036854775808}
!10 = !{}
!11 = !{i64 0, i64 2}
!12 = !{i64 0, i64 -9223372036854775807}
!13 = !{i64 -5752278552975595893}
!14 = !{!15}
!15 = distinct !{!15, !16, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14grow_amortizedCsYR6quqRMAk_6tier_b: %self"}
!16 = distinct !{!16, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14grow_amortizedCsYR6quqRMAk_6tier_b"}
!17 = !{i64 -5122489595040398537}
!18 = !{!"branch_weights", i32 2002, i32 2000}
!19 = !{!20}
!20 = distinct !{!20, !21, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %self"}
!21 = distinct !{!21, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b"}
!22 = !{!23}
!23 = distinct !{!23, !21, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %_0"}
!24 = !{i64 -6189157931474602459}
!25 = !{!26}
!26 = distinct !{!26, !27, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b: %_0"}
!27 = distinct !{!27, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b"}
!28 = !{!29}
!29 = distinct !{!29, !30, !"_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b: %self"}
!30 = distinct !{!30, !"_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE15append_elementsCsYR6quqRMAk_6tier_b"}
!31 = !{!32}
!32 = distinct !{!32, !33, !"_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push: %self"}
!33 = distinct !{!33, !"_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push"}
!34 = !{!35, !32}
!35 = distinct !{!35, !36, !"_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE7reserveCsYR6quqRMAk_6tier_b: %self"}
!36 = distinct !{!36, !"_RNvMs_NtCsgFX3jaOk65H_5alloc3vecINtB4_3VechE7reserveCsYR6quqRMAk_6tier_b"}
!37 = !{!"branch_weights", !"expected", i32 1, i32 2000}
!38 = !{!39}
!39 = distinct !{!39, !33, !"_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push: %self:It2"}
!40 = !{!35, !41}
!41 = distinct !{!41, !33, !"_RNvMNtCsgFX3jaOk65H_5alloc6stringNtB2_6String4push: %self:It1"}
!42 = !{!41}
!43 = !{!35, !39}
!44 = distinct !{!44, !45}
!45 = !{!"llvm.loop.unroll.disable"}
!46 = !{!47}
!47 = distinct !{!47, !48, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueNtNtCsgFX3jaOk65H_5alloc6string6StringECsYR6quqRMAk_6tier_b: %_1"}
!48 = distinct !{!48, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueNtNtCsgFX3jaOk65H_5alloc6string6StringECsYR6quqRMAk_6tier_b"}
!49 = !{!50}
!50 = distinct !{!50, !51, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VechEECsYR6quqRMAk_6tier_b: %_1"}
!51 = distinct !{!51, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VechEECsYR6quqRMAk_6tier_b"}
!52 = !{!53}
!53 = distinct !{!53, !54, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVechEECsYR6quqRMAk_6tier_b: %_1"}
!54 = distinct !{!54, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVechEECsYR6quqRMAk_6tier_b"}
!55 = !{!56}
!56 = distinct !{!56, !57, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVechENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!57 = distinct !{!57, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVechENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!58 = !{!59}
!59 = distinct !{!59, !60, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!60 = distinct !{!60, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!61 = !{!62, !59, !56, !53, !50, !47}
!62 = distinct !{!62, !63, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %self"}
!63 = distinct !{!63, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b"}
!64 = !{!65}
!65 = distinct !{!65, !63, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %_0"}
!66 = !{!59, !56, !53, !50, !47}
!67 = !{i64 -6271275605676525415}
!68 = !{!69, !71, !73, !74, !76, !77, !79, !80}
!69 = distinct !{!69, !70, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b: %_0"}
!70 = distinct !{!70, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b"}
!71 = distinct !{!71, !72, !"_RINvXs_NvMNtCsgFX3jaOk65H_5alloc5sliceSp9to_vec_inhNtB5_10ConvertVec6to_vecNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b: %v"}
!72 = distinct !{!72, !"_RINvXs_NvMNtCsgFX3jaOk65H_5alloc5sliceSp9to_vec_inhNtB5_10ConvertVec6to_vecNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b"}
!73 = distinct !{!73, !72, !"_RINvXs_NvMNtCsgFX3jaOk65H_5alloc5sliceSp9to_vec_inhNtB5_10ConvertVec6to_vecNtNtBa_5alloc6GlobalECsYR6quqRMAk_6tier_b: %s.0"}
!74 = distinct !{!74, !75, !"_RNvXs2_NtCsgFX3jaOk65H_5alloc3streNtNtB7_6borrow7ToOwned8to_owned: %_0"}
!75 = distinct !{!75, !"_RNvXs2_NtCsgFX3jaOk65H_5alloc3streNtNtB7_6borrow7ToOwned8to_owned"}
!76 = distinct !{!76, !75, !"_RNvXs2_NtCsgFX3jaOk65H_5alloc3streNtNtB7_6borrow7ToOwned8to_owned: %self.0"}
!77 = distinct !{!77, !78, !"_RNvYNvYeNtNtCsgFX3jaOk65H_5alloc6borrow7ToOwned8to_ownedINtNtNtCskADBYZwJmSU_4core3ops8function6FnOnceTReEE9call_onceCsYR6quqRMAk_6tier_b: %_0"}
!78 = distinct !{!78, !"_RNvYNvYeNtNtCsgFX3jaOk65H_5alloc6borrow7ToOwned8to_ownedINtNtNtCskADBYZwJmSU_4core3ops8function6FnOnceTReEE9call_onceCsYR6quqRMAk_6tier_b"}
!79 = distinct !{!79, !78, !"_RNvYNvYeNtNtCsgFX3jaOk65H_5alloc6borrow7ToOwned8to_ownedINtNtNtCskADBYZwJmSU_4core3ops8function6FnOnceTReEE9call_onceCsYR6quqRMAk_6tier_b: argument 1"}
!80 = distinct !{!80, !81, !"_RINvMNtCskADBYZwJmSU_4core6optionINtB3_6OptionReE11map_or_elseNtNtCsgFX3jaOk65H_5alloc6string6StringNCNvNtB12_3fmt6format0NvYeNtNtB12_6borrow7ToOwned8to_ownedECsYR6quqRMAk_6tier_b: %_0"}
!81 = distinct !{!81, !"_RINvMNtCskADBYZwJmSU_4core6optionINtB3_6OptionReE11map_or_elseNtNtCsgFX3jaOk65H_5alloc6string6StringNCNvNtB12_3fmt6format0NvYeNtNtB12_6borrow7ToOwned8to_ownedECsYR6quqRMAk_6tier_b"}
!82 = !{i64 -8778930059445740646}
!83 = !{!84, !86}
!84 = distinct !{!84, !85, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b: %_0"}
!85 = distinct !{!85, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b"}
!86 = distinct !{!86, !85, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB4_3VecReEINtB2_18SpecFromIterNestedB11_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE9from_iterCsYR6quqRMAk_6tier_b: %iterator"}
!87 = !{!88, !90, !91, !93, !84, !86}
!88 = distinct !{!88, !89, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match: %_0"}
!89 = distinct !{!89, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match"}
!90 = distinct !{!90, !89, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match: %self"}
!91 = distinct !{!91, !92, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE4nextCsYR6quqRMAk_6tier_b: %self"}
!92 = distinct !{!92, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE4nextCsYR6quqRMAk_6tier_b"}
!93 = distinct !{!93, !94, !"_RNvXsX_NtNtCskADBYZwJmSU_4core3str4iterINtB5_5SplitcENtNtNtNtB9_4iter6traits8iterator8Iterator4nextCsYR6quqRMAk_6tier_b: %self"}
!94 = distinct !{!94, !"_RNvXsX_NtNtCskADBYZwJmSU_4core3str4iterINtB5_5SplitcENtNtNtNtB9_4iter6traits8iterator8Iterator4nextCsYR6quqRMAk_6tier_b"}
!95 = !{!96}
!96 = distinct !{!96, !97, !"_RNvNtNtCskADBYZwJmSU_4core5slice6memchr6memchr: %text.0"}
!97 = distinct !{!97, !"_RNvNtNtCskADBYZwJmSU_4core5slice6memchr6memchr"}
!98 = !{!99, !84, !86}
!99 = distinct !{!99, !100, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b: %_0"}
!100 = distinct !{!100, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b"}
!101 = !{!"address", !"read_provenance"}
!102 = !{!84}
!103 = !{!104}
!104 = distinct !{!104, !105, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB4_3VecReEINtB2_10SpecExtendBR_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE11spec_extendCsYR6quqRMAk_6tier_b: %self"}
!105 = distinct !{!105, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB4_3VecReEINtB2_10SpecExtendBR_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE11spec_extendCsYR6quqRMAk_6tier_b"}
!106 = !{!107}
!107 = distinct !{!107, !105, !"_RNvXNtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB4_3VecReEINtB2_10SpecExtendBR_INtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEE11spec_extendCsYR6quqRMAk_6tier_b: %iter"}
!108 = !{!109}
!109 = distinct !{!109, !110, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecReE16extend_desugaredINtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEECsYR6quqRMAk_6tier_b: %self"}
!110 = distinct !{!110, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecReE16extend_desugaredINtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEECsYR6quqRMAk_6tier_b"}
!111 = !{!112}
!112 = distinct !{!112, !110, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecReE16extend_desugaredINtNtNtCskADBYZwJmSU_4core3str4iter5SplitcEECsYR6quqRMAk_6tier_b: %iterator"}
!113 = !{!112, !107}
!114 = !{!109, !104, !84, !86}
!115 = !{!116, !118, !120, !112, !107}
!116 = distinct !{!116, !117, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher8haystack: %self"}
!117 = distinct !{!117, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher8haystack"}
!118 = distinct !{!118, !119, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE4nextCsYR6quqRMAk_6tier_b: %self"}
!119 = distinct !{!119, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE4nextCsYR6quqRMAk_6tier_b"}
!120 = distinct !{!120, !121, !"_RNvXsX_NtNtCskADBYZwJmSU_4core3str4iterINtB5_5SplitcENtNtNtNtB9_4iter6traits8iterator8Iterator4nextCsYR6quqRMAk_6tier_b: %self"}
!121 = distinct !{!121, !"_RNvXsX_NtNtCskADBYZwJmSU_4core3str4iterINtB5_5SplitcENtNtNtNtB9_4iter6traits8iterator8Iterator4nextCsYR6quqRMAk_6tier_b"}
!122 = !{!123, !118, !120, !112, !107}
!123 = distinct !{!123, !124, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match: %self"}
!124 = distinct !{!124, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match"}
!125 = !{!126, !109, !104, !84, !86}
!126 = distinct !{!126, !124, !"_RNvXs_NtNtCskADBYZwJmSU_4core3str7patternNtB4_12CharSearcherNtB4_8Searcher10next_match: %_0"}
!127 = !{i8 0, i8 2}
!128 = !{!120}
!129 = !{!118}
!130 = !{!123}
!131 = !{!126, !123, !118, !120, !109, !112, !104, !107, !84, !86}
!132 = !{!133}
!133 = distinct !{!133, !134, !"_RNvNtNtCskADBYZwJmSU_4core5slice6memchr6memchr: %text.0"}
!134 = distinct !{!134, !"_RNvNtNtCskADBYZwJmSU_4core5slice6memchr6memchr"}
!135 = !{!136, !118, !120, !112, !107}
!136 = distinct !{!136, !137, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE7get_endCsYR6quqRMAk_6tier_b: %self"}
!137 = distinct !{!137, !"_RNvMsf_NtNtCskADBYZwJmSU_4core3str4iterINtB5_13SplitInternalcE7get_endCsYR6quqRMAk_6tier_b"}
!138 = !{!109, !104}
!139 = !{!112, !107, !84, !86}
!140 = !{!109, !112, !104, !107, !84, !86}
!141 = !{!86}
!142 = distinct !{!142, !45}
!143 = !{!144, !146, !148, !150}
!144 = distinct !{!144, !145, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!145 = distinct !{!145, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!146 = distinct !{!146, !147, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecReENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!147 = distinct !{!147, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecReENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!148 = distinct !{!148, !149, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecReEECsYR6quqRMAk_6tier_b: %_1"}
!149 = distinct !{!149, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecReEECsYR6quqRMAk_6tier_b"}
!150 = distinct !{!150, !151, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecReEECsYR6quqRMAk_6tier_b: %_1"}
!151 = distinct !{!151, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecReEECsYR6quqRMAk_6tier_b"}
!152 = !{i64 -732399604055381295}
!153 = !{!154, !156}
!154 = distinct !{!154, !155, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b: %_0"}
!155 = distinct !{!155, !"_RNvMs5_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner15try_allocate_inCsYR6quqRMAk_6tier_b"}
!156 = distinct !{!156, !157, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB6_3VecyEINtB4_18SpecFromIterNestedyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE9from_iterCsYR6quqRMAk_6tier_b: %_0"}
!157 = distinct !{!157, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec21spec_from_iter_nestedINtB6_3VecyEINtB4_18SpecFromIterNestedyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE9from_iterCsYR6quqRMAk_6tier_b"}
!158 = !{!159, !161, !163, !165, !167, !169, !156}
!159 = distinct !{!159, !160, !"_RNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB8_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE0CsYR6quqRMAk_6tier_b: %_1"}
!160 = distinct !{!160, !"_RNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB8_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE0CsYR6quqRMAk_6tier_b"}
!161 = distinct !{!161, !162, !"_RNCINvNvNtNtNtNtCskADBYZwJmSU_4core4iter6traits8iterator8Iterator8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1p_3VecyE14extend_trustedINtNtNtBe_3ops5range5RangeyEE0E0CsYR6quqRMAk_6tier_b: %_1"}
!162 = distinct !{!162, !"_RNCINvNvNtNtNtNtCskADBYZwJmSU_4core4iter6traits8iterator8Iterator8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1p_3VecyE14extend_trustedINtNtNtBe_3ops5range5RangeyEE0E0CsYR6quqRMAk_6tier_b"}
!163 = distinct !{!163, !164, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator4folduNCINvNvBL_8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB24_3VecyE14extend_trustedB3_E0E0ECsYR6quqRMAk_6tier_b: %f"}
!164 = distinct !{!164, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator4folduNCINvNvBL_8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB24_3VecyE14extend_trustedB3_E0E0ECsYR6quqRMAk_6tier_b"}
!165 = distinct !{!165, !166, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator8for_eachNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1I_3VecyE14extend_trustedB3_E0ECsYR6quqRMAk_6tier_b: %f"}
!166 = distinct !{!166, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator8for_eachNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1I_3VecyE14extend_trustedB3_E0ECsYR6quqRMAk_6tier_b"}
!167 = distinct !{!167, !168, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEECsYR6quqRMAk_6tier_b: %self"}
!168 = distinct !{!168, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEECsYR6quqRMAk_6tier_b"}
!169 = distinct !{!169, !170, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB6_3VecyEINtB4_10SpecExtendyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE11spec_extendCsYR6quqRMAk_6tier_b: %self"}
!170 = distinct !{!170, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB6_3VecyEINtB4_10SpecExtendyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE11spec_extendCsYR6quqRMAk_6tier_b"}
!171 = distinct !{!171, !172, !173}
!172 = !{!"llvm.loop.isvectorized", i32 1}
!173 = !{!"llvm.loop.unroll.runtime.disable"}
!174 = !{!156}
!175 = distinct !{!175, !173, !172}
!176 = !{!177}
!177 = distinct !{!177, !178, !"_RNCINvNtNtNtCskADBYZwJmSU_4core4iter8adapters6filter11filter_foldRyyNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0NCINvNtB6_3map8map_foldB11_yyNCB16_s_0NCINvXsC_NtNtB8_6traits5accumyNtB2u_3Sum3sumINtB1O_3MapINtB4_6FilterINtNtNtBa_5slice4iter4IteryEB14_EB2c_EE0E0E0B18_: argument 0"}
!178 = distinct !{!178, !"_RNCINvNtNtNtCskADBYZwJmSU_4core4iter8adapters6filter11filter_foldRyyNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0NCINvNtB6_3map8map_foldB11_yyNCB16_s_0NCINvXsC_NtNtB8_6traits5accumyNtB2u_3Sum3sumINtB1O_3MapINtB4_6FilterINtNtNtBa_5slice4iter4IteryEB14_EB2c_EE0E0E0B18_"}
!179 = !{!180}
!180 = distinct !{!180, !181, !"_RNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0B3_: %x"}
!181 = distinct !{!181, !"_RNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0B3_"}
!182 = !{!183, !185, !187, !189}
!183 = distinct !{!183, !184, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!184 = distinct !{!184, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!185 = distinct !{!185, !186, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!186 = distinct !{!186, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!187 = distinct !{!187, !188, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b: %_1"}
!188 = distinct !{!188, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b"}
!189 = distinct !{!189, !190, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b: %_1"}
!190 = distinct !{!190, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b"}
!191 = !{i64 -8937385220296713055}
!192 = distinct !{!192, !172, !173}
!193 = !{!194}
!194 = distinct !{!194, !195, !"_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b: %self"}
!195 = distinct !{!195, !"_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b"}
!196 = distinct !{!196, !173, !172}
!197 = !{!198}
!198 = distinct !{!198, !199, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b: %_1"}
!199 = distinct !{!199, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b"}
!200 = !{!201}
!201 = distinct !{!201, !202, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b: %_1"}
!202 = distinct !{!202, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b"}
!203 = !{!204}
!204 = distinct !{!204, !205, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!205 = distinct !{!205, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!206 = !{!207}
!207 = distinct !{!207, !208, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!208 = distinct !{!208, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!209 = !{!210, !207, !204, !201, !198}
!210 = distinct !{!210, !211, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %self"}
!211 = distinct !{!211, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b"}
!212 = !{!213}
!213 = distinct !{!213, !211, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %_0"}
!214 = !{!207, !204, !201, !198}
