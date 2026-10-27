; ModuleID = 'tier_b.b6ecbca91df9d46-cgu.0'
source_filename = "tier_b.b6ecbca91df9d46-cgu.0"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@alloc_e342eacdbf38ee6e7c7878ca690b4e0f = private unnamed_addr constant [23 x i8] c"alpha,beta,,gamma,delta", align 1, !guid !0

; <alloc::raw_vec::RawVecInner<_>>::reserve::do_reserve_and_handle::<alloc::alloc::Global>
; Function Attrs: cold nounwind nonlazybind uwtable

; <alloc::raw_vec::RawVec<u64>>::grow_one
; Function Attrs: cold noinline nounwind nonlazybind uwtable

; <alloc::raw_vec::RawVecInner>::finish_grow
; Function Attrs: cold nounwind nonlazybind uwtable

; Function Attrs: cold nounwind nonlazybind uwtable

; Function Attrs: nounwind nonlazybind uwtable

; Function Attrs: nounwind nonlazybind uwtable

; Function Attrs: nounwind nonlazybind uwtable

; Function Attrs: nounwind nonlazybind uwtable

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

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #12

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
!158 = !{!156}
!159 = !{!160, !162, !164, !166, !168, !170, !156}
!160 = distinct !{!160, !161, !"_RNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB8_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE0CsYR6quqRMAk_6tier_b: %_1"}
!161 = distinct !{!161, !"_RNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB8_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE0CsYR6quqRMAk_6tier_b"}
!162 = distinct !{!162, !163, !"_RNCINvNvNtNtNtNtCskADBYZwJmSU_4core4iter6traits8iterator8Iterator8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1p_3VecyE14extend_trustedINtNtNtBe_3ops5range5RangeyEE0E0CsYR6quqRMAk_6tier_b: %_1"}
!163 = distinct !{!163, !"_RNCINvNvNtNtNtNtCskADBYZwJmSU_4core4iter6traits8iterator8Iterator8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1p_3VecyE14extend_trustedINtNtNtBe_3ops5range5RangeyEE0E0CsYR6quqRMAk_6tier_b"}
!164 = distinct !{!164, !165, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator4folduNCINvNvBL_8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB24_3VecyE14extend_trustedB3_E0E0ECsYR6quqRMAk_6tier_b: %f"}
!165 = distinct !{!165, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator4folduNCINvNvBL_8for_each4callyNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB24_3VecyE14extend_trustedB3_E0E0ECsYR6quqRMAk_6tier_b"}
!166 = distinct !{!166, !167, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator8for_eachNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1I_3VecyE14extend_trustedB3_E0ECsYR6quqRMAk_6tier_b: %f"}
!167 = distinct !{!167, !"_RINvYINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyENtNtNtNtBa_4iter6traits8iterator8Iterator8for_eachNCINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB1I_3VecyE14extend_trustedB3_E0ECsYR6quqRMAk_6tier_b"}
!168 = distinct !{!168, !169, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEECsYR6quqRMAk_6tier_b: %self"}
!169 = distinct !{!169, !"_RINvMsk_NtCsgFX3jaOk65H_5alloc3vecINtB6_3VecyE14extend_trustedINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEECsYR6quqRMAk_6tier_b"}
!170 = distinct !{!170, !171, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB6_3VecyEINtB4_10SpecExtendyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE11spec_extendCsYR6quqRMAk_6tier_b: %self"}
!171 = distinct !{!171, !"_RNvXs_NtNtCsgFX3jaOk65H_5alloc3vec11spec_extendINtB6_3VecyEINtB4_10SpecExtendyINtNtNtCskADBYZwJmSU_4core3ops5range5RangeyEE11spec_extendCsYR6quqRMAk_6tier_b"}
!172 = distinct !{!172, !45}
!173 = !{!174}
!174 = distinct !{!174, !175, !"_RNCINvNtNtNtCskADBYZwJmSU_4core4iter8adapters6filter11filter_foldRyyNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0NCINvNtB6_3map8map_foldB11_yyNCB16_s_0NCINvXsC_NtNtB8_6traits5accumyNtB2u_3Sum3sumINtB1O_3MapINtB4_6FilterINtNtNtBa_5slice4iter4IteryEB14_EB2c_EE0E0E0B18_: argument 0"}
!175 = distinct !{!175, !"_RNCINvNtNtNtCskADBYZwJmSU_4core4iter8adapters6filter11filter_foldRyyNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0NCINvNtB6_3map8map_foldB11_yyNCB16_s_0NCINvXsC_NtNtB8_6traits5accumyNtB2u_3Sum3sumINtB1O_3MapINtB4_6FilterINtNtNtBa_5slice4iter4IteryEB14_EB2c_EE0E0E0B18_"}
!176 = !{!177}
!177 = distinct !{!177, !178, !"_RNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0B3_: %x"}
!178 = distinct !{!178, !"_RNCNvCsYR6quqRMAk_6tier_b14vec_filter_sum0B3_"}
!179 = !{!180, !182, !184, !186}
!180 = distinct !{!180, !181, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!181 = distinct !{!181, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!182 = distinct !{!182, !183, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!183 = distinct !{!183, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!184 = distinct !{!184, !185, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b: %_1"}
!185 = distinct !{!185, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b"}
!186 = distinct !{!186, !187, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b: %_1"}
!187 = distinct !{!187, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b"}
!188 = !{i64 -8937385220296713055}
!189 = !{!190}
!190 = distinct !{!190, !191, !"_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b: %self"}
!191 = distinct !{!191, !"_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b"}
!192 = distinct !{!192, !45}
!193 = !{!194}
!194 = distinct !{!194, !195, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b: %_1"}
!195 = distinct !{!195, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b"}
!196 = !{!197}
!197 = distinct !{!197, !198, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b: %_1"}
!198 = distinct !{!198, !"_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc7raw_vec6RawVecyEECsYR6quqRMAk_6tier_b"}
!199 = !{!200}
!200 = distinct !{!200, !201, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b: %self"}
!201 = distinct !{!201, !"_RNvXs1_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyENtNtNtCskADBYZwJmSU_4core3ops4drop4Drop4dropCsYR6quqRMAk_6tier_b"}
!202 = !{!203}
!203 = distinct !{!203, !204, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b: %self"}
!204 = distinct !{!204, !"_RNvMs3_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner10deallocateCsYR6quqRMAk_6tier_b"}
!205 = !{!206, !203, !200, !197, !194}
!206 = distinct !{!206, !207, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %self"}
!207 = distinct !{!207, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b"}
!208 = !{!209}
!209 = distinct !{!209, !207, !"_RNvMs2_NtCsgFX3jaOk65H_5alloc7raw_vecNtB5_11RawVecInner14current_memoryCsYR6quqRMAk_6tier_b: %_0"}
!210 = !{!203, !200, !197, !194}

define noundef i64 @vec_sum(i32 noundef %n) unnamed_addr #2 personality ptr @rust_eh_personality !guid !188 {
start:
  %v = alloca [24 x i8], align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %v)
  store i64 0, ptr %v, align 8
  %0 = getelementptr inbounds nuw i8, ptr %v, i64 8
  store ptr null, ptr %0, align 8
  %1 = getelementptr inbounds nuw i8, ptr %v, i64 16
  store i64 0, ptr %1, align 8
  %_6 = zext i32 %n to i64
  %_45.not = icmp eq i32 %n, 0
  br i1 %_45.not, label %bb7, label %bb2

bb3:                                              ; preds = %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit
  %_18.pre = load ptr, ptr %0, align 8
  %_287 = icmp eq i64 %6, 0
  br i1 %_287, label %bb7, label %bb8.preheader

bb8.preheader:                                    ; preds = %bb3
  %2 = add nuw nsw i64 %_6, 2305843009213693951
  %3 = and i64 %2, 2305843009213693951
  %4 = add nuw nsw i64 %3, 1
  %xtraiter = and i64 %4, 7
  %5 = icmp ult i64 %3, 7
  br i1 %5, label %bb8.epil.preheader, label %bb8.preheader.new

bb8.preheader.new:                                ; preds = %bb8.preheader
  %unroll_iter = and i64 %4, 4611686018427387896
  br label %bb8

bb2:                                              ; preds = %start, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit
  %_14.i14 = phi ptr [ %_14.i, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ inttoptr (i64 8 to ptr), %start ]
  %self1.i = phi i64 [ %self1.i12, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %len.i = phi i64 [ %6, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %i.sroa.0.06 = phi i64 [ %7, %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit ], [ 0, %start ]
  %_8 = mul nuw i64 %i.sroa.0.06, %i.sroa.0.06
  %_4.i = icmp eq i64 %len.i, %self1.i
  br i1 %_4.i, label %bb1.i, label %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit

bb1.i:                                            ; preds = %bb2
; call <alloc::raw_vec::RawVec<u64>>::grow_one
  call void @_RNvMs4_NtCsgFX3jaOk65H_5alloc7raw_vecINtB5_6RawVecyE8grow_oneCsYR6quqRMAk_6tier_b(ptr noalias nofree noundef nonnull align 8 dereferenceable(24) %v) #15
  %self1.i.pre = load i64, ptr %v, align 8, !range !9
  %_14.i.pre = load ptr, ptr %0, align 8
  br label %_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit

_RNvMsG_NtCsgFX3jaOk65H_5alloc3vecINtB5_3VecyE8push_mutCsYR6quqRMAk_6tier_b.exit: ; preds = %bb2, %bb1.i
  %_14.i = phi ptr [ %_14.i14, %bb2 ], [ %_14.i.pre, %bb1.i ]
  %self1.i12 = phi i64 [ %self1.i, %bb2 ], [ %self1.i.pre, %bb1.i ]
  %end.i = getelementptr inbounds nuw [8 x i8], ptr %_14.i, i64 %len.i
  store i64 %_8, ptr %end.i, align 8
  %6 = add i64 %len.i, 1
  store i64 %6, ptr %1, align 8
  %7 = add nuw nsw i64 %i.sroa.0.06, 1
  %exitcond.not = icmp eq i64 %7, %_6
  br i1 %exitcond.not, label %bb3, label %bb2

bb8:                                              ; preds = %bb8, %bb8.preheader.new
  %s.sroa.0.09 = phi i64 [ 0, %bb8.preheader.new ], [ %_37.0.7, %bb8 ]
  %iter.sroa.0.08 = phi ptr [ %_18.pre, %bb8.preheader.new ], [ %_34.7, %bb8 ]
  %niter = phi i64 [ 0, %bb8.preheader.new ], [ %niter.next.7, %bb8 ]
  %_34 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 8
  %_36 = load i64, ptr %iter.sroa.0.08, align 8
  %_37.0 = add i64 %_36, %s.sroa.0.09
  %_34.1 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 16
  %_36.1 = load i64, ptr %_34, align 8
  %_37.0.1 = add i64 %_36.1, %_37.0
  %_34.2 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 24
  %_36.2 = load i64, ptr %_34.1, align 8
  %_37.0.2 = add i64 %_36.2, %_37.0.1
  %_34.3 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 32
  %_36.3 = load i64, ptr %_34.2, align 8
  %_37.0.3 = add i64 %_36.3, %_37.0.2
  %_34.4 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 40
  %_36.4 = load i64, ptr %_34.3, align 8
  %_37.0.4 = add i64 %_36.4, %_37.0.3
  %_34.5 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 48
  %_36.5 = load i64, ptr %_34.4, align 8
  %_37.0.5 = add i64 %_36.5, %_37.0.4
  %_34.6 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 56
  %_36.6 = load i64, ptr %_34.5, align 8
  %_37.0.6 = add i64 %_36.6, %_37.0.5
  %_34.7 = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08, i64 64
  %_36.7 = load i64, ptr %_34.6, align 8
  %_37.0.7 = add i64 %_36.7, %_37.0.6
  %niter.next.7 = add i64 %niter, 8
  %niter.ncmp.7 = icmp eq i64 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %bb7.loopexit.unr-lcssa, label %bb8

bb7.loopexit.unr-lcssa:                           ; preds = %bb8
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod.not, label %bb7, label %bb8.epil.preheader

bb8.epil.preheader:                               ; preds = %bb7.loopexit.unr-lcssa, %bb8.preheader
  %s.sroa.0.09.epil.init = phi i64 [ 0, %bb8.preheader ], [ %_37.0.7, %bb7.loopexit.unr-lcssa ]
  %iter.sroa.0.08.epil.init = phi ptr [ %_18.pre, %bb8.preheader ], [ %_34.7, %bb7.loopexit.unr-lcssa ]
  %lcmp.mod25 = icmp ne i64 %xtraiter, 0
  tail call void @llvm.assume(i1 %lcmp.mod25)
  br label %bb8.epil

bb8.epil:                                         ; preds = %bb8.epil, %bb8.epil.preheader
  %s.sroa.0.09.epil = phi i64 [ %_37.0.epil, %bb8.epil ], [ %s.sroa.0.09.epil.init, %bb8.epil.preheader ]
  %iter.sroa.0.08.epil = phi ptr [ %_34.epil, %bb8.epil ], [ %iter.sroa.0.08.epil.init, %bb8.epil.preheader ]
  %epil.iter = phi i64 [ %epil.iter.next, %bb8.epil ], [ 0, %bb8.epil.preheader ]
  %_34.epil = getelementptr inbounds nuw i8, ptr %iter.sroa.0.08.epil, i64 8
  %_36.epil = load i64, ptr %iter.sroa.0.08.epil, align 8
  %_37.0.epil = add i64 %_36.epil, %s.sroa.0.09.epil
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %bb7, label %bb8.epil

bb7:                                              ; preds = %bb7.loopexit.unr-lcssa, %bb8.epil, %start, %bb3
  %_1823 = phi ptr [ %_18.pre, %bb3 ], [ inttoptr (i64 8 to ptr), %start ], [ %_18.pre, %bb8.epil ], [ %_18.pre, %bb7.loopexit.unr-lcssa ]
  %s.sroa.0.0.lcssa = phi i64 [ 0, %bb3 ], [ 0, %start ], [ %_37.0.7, %bb7.loopexit.unr-lcssa ], [ %_37.0.epil, %bb8.epil ]
  %self1.i.i.i.i.i = load i64, ptr %v, align 8, !range !9, !alias.scope !205, !noalias !208
  %8 = icmp eq i64 %self1.i.i.i.i.i, 0
  br i1 %8, label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit, label %bb2.i.i.i.i

bb2.i.i.i.i:                                      ; preds = %bb7
  %alloc_size.i.i.i.i.i = shl nuw i64 %self1.i.i.i.i.i, 3
; call __rustc::__rust_dealloc
  tail call void @_RNvCs5fGHjzWXRav_7___rustc14___rust_dealloc(ptr noundef nonnull %_1823, i64 noundef %alloc_size.i.i.i.i.i, i64 noundef range(i64 1, -9223372036854775807) 8) #13
  br label %_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit

_RINvNtCskADBYZwJmSU_4core3ptr9drop_glueINtNtCsgFX3jaOk65H_5alloc3vec3VecyEECsYR6quqRMAk_6tier_b.exit: ; preds = %bb7, %bb2.i.i.i.i
  call void @llvm.lifetime.end.p0(ptr nonnull %v)
  ret i64 %s.sroa.0.0.lcssa
}
