; RUN: clspv -x=ir %s -o %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env vulkan1.0

; RUN: clspv-opt %s --passes=replace-llvm-intrinsics -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[cmp:%[^ ]+]] = icmp sgt
; CHECK-NEXT: br i1 [[cmp]], label %[[preheaderBB:[^ ]+]], label %[[exitBB:[^ ]+]]

; CHECK: [[preheaderBB]]:
; CHECK-NEXT: [[len:%[^ ]+]] = shl nuw i32
; CHECK-NEXT: br label %[[headerBB:[^ ]+]]

; CHECK: [[postBB:[^ ]+]]:
; CHECK-NEXT: br label %[[exitBB]]

; CHECK: [[exitBB]]:
; CHECK-NEXT: ret void

; CHECK: [[headerBB]]:
; CHECK-NEXT: [[phi:%[^ ]+]] = phi i32 [ 0, %[[preheaderBB]] ], [ [[next:%[^ ]+]], %[[loopBB:[^ ]+]] ]
; CHECK-NEXT: [[cmp:%[^ ]+]] = icmp ult i32 [[phi]], [[len]]
; CHECK-NEXT: br i1 [[cmp]], label %[[loopBB]], label %[[postBB]]

; CHECK: [[loopBB]]:
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %0, i32 [[phi]]
; CHECK-NEXT: store i8 -1, ptr addrspace(1) [[gep]]
; CHECK-NEXT: [[next]] = add i32 [[phi]], 1
; CHECK-NEXT: br label %[[headerBB]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spirv-unknown-vulkan"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write)
define dso_local spir_kernel void @foo(ptr addrspace(1) noundef writeonly align 4 captures(none) %0, i32 noundef %1) local_unnamed_addr #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = shl nuw i32 %1, 2
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) align 4 %0, i8 -1, i32 %5, i1 false), !tbaa !8
  br label %6

6:                                                ; preds = %4, %2
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p1.i32(ptr addrspace(1) writeonly captures(none), i8, i32, i1 immarg) #2

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { alwaysinline mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{!"Ubuntu clang version 21.1.2 (2ubuntu6)"}
!4 = !{i32 1, i32 0}
!5 = !{!"none", !"none"}
!6 = !{!"int*", !"int"}
!7 = !{!"", !""}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}

