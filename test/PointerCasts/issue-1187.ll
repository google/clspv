; RUN: clspv %s -o %t.spv -cl-std=CLC++ -inline-entry-points -physical-storage-buffers -arch=spir64 -cl-kernel-arg-info -x=ir
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env spv1.0

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; Function Attrs: convergent nofree norecurse nounwind memory(readwrite, inaccessiblemem: none)
define dso_local spir_kernel void @BeamMeUp(ptr addrspace(1) noundef %0, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %1) local_unnamed_addr #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 !reqd_work_group_size !8 {
  %3 = tail call spir_func noundef i64 @_Z12get_local_idj(i32 noundef 0) #2
  %4 = trunc i64 %3 to i32
  %5 = tail call spir_func noundef i64 @_Z12get_group_idj(i32 noundef 0) #2
  %6 = trunc i64 %5 to i32
  %7 = shl i32 %6, 7
  %8 = add i32 %7, %4
  %9 = addrspacecast ptr addrspace(1) %0 to ptr addrspace(4)
  %10 = ptrtoint ptr addrspace(4) %9 to i64
  %11 = add i64 %10, 7
  %12 = and i64 %11, -8
  %13 = inttoptr i64 %12 to ptr addrspace(1)
  %14 = load i64, ptr addrspace(1) %13, align 8, !tbaa !9
  %15 = freeze i64 %14
  %16 = add i64 %15, 7
  %17 = and i64 %16, -8
  %18 = inttoptr i64 %17 to ptr addrspace(1)
  %19 = load i64, ptr addrspace(1) %18, align 8, !tbaa !9
  %20 = freeze i64 %19
  %21 = add i64 %20, 15
  %22 = and i64 %21, -16
  %23 = icmp slt i32 %8, 1000000
  br i1 %23, label %24, label %41

24:                                               ; preds = %2, %24
  %25 = phi i32 [ %39, %24 ], [ %8, %2 ]
  %26 = sext i32 %25 to i64
  %27 = shl nsw i64 %26, 3
  %28 = add nsw i64 %27, %22
  %29 = inttoptr i64 %28 to ptr addrspace(1)
  %30 = addrspacecast ptr addrspace(1) %29 to ptr addrspace(4)
  %31 = load i64, ptr addrspace(4) %30, align 2, !noalias !13
  %32 = lshr i64 %31, 16
  %33 = trunc i64 %32 to i16
  %34 = lshr i64 %31, 32
  %35 = trunc i64 %34 to i16
  store half 0xH3C00, ptr addrspace(4) %30, align 2
  %36 = getelementptr inbounds i8, ptr addrspace(4) %30, i64 2
  store i16 %33, ptr addrspace(4) %36, align 2
  %37 = getelementptr inbounds i8, ptr addrspace(4) %30, i64 4
  store i16 %35, ptr addrspace(4) %37, align 2
  %38 = getelementptr inbounds i8, ptr addrspace(4) %30, i64 6
  store i16 0, ptr addrspace(4) %38, align 2
  %39 = add i32 %25, 14336
  %40 = icmp slt i32 %39, 1000000
  br i1 %40, label %24, label %41, !llvm.loop !16

41:                                               ; preds = %24, %2
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func noundef i64 @_Z12get_local_idj(i32 noundef) local_unnamed_addr #1

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare dso_local spir_func noundef i64 @_Z12get_group_idj(i32 noundef) local_unnamed_addr #1

attributes #0 = { convergent nofree norecurse nounwind memory(readwrite, inaccessiblemem: none) "approx-func-fp-math"="true" "frame-pointer"="all" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" "unsafe-fp-math"="true" }
attributes #1 = { convergent mustprogress nofree nounwind willreturn memory(none) "approx-func-fp-math"="true" "frame-pointer"="all" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { alwaysinline convergent nounwind willreturn memory(none) }

!llvm.linker.options = !{}
!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 3, i32 0}
!3 = !{!"clang version 18.0.0 (https://github.com/llvm/llvm-project 2ef0d007a72e9622f04a5f2cf613fcad2470a7a3)"}
!4 = !{i32 1, i32 1}
!5 = !{!"none", !"write_only"}
!6 = !{!"void*", !"image2d_t"}
!7 = !{!"", !""}
!8 = !{i32 128, i32 1, i32 1}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C++ TBAA"}
!13 = !{!14}
!14 = distinct !{!14, !15, !"_ZNU3AS46beyond9Samples2DINS_11SampleRGB48EE4ReadENS_8Vector2DIiEE: argument 0"}
!15 = distinct !{!15, !"_ZNU3AS46beyond9Samples2DINS_11SampleRGB48EE4ReadENS_8Vector2DIiEE"}
!16 = distinct !{!16, !17}
!17 = !{!"llvm.loop.mustprogress"}
