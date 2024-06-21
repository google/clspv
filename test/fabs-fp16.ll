; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm

; CHECK: [[ushort:%[^ ]+]] = OpTypeInt 16 0
; CHECK: [[ushort_7fff:%[^ ]+]] = OpConstant [[ushort]] 32767
; CHECK: OpBitwiseAnd [[ushort]] {{.*}} [[ushort_7fff]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent mustprogress nofree norecurse nounwind willreturn memory(read, argmem: readwrite, inaccessiblemem: none)
define dso_local spir_kernel void @test_simple(ptr addrspace(1) nocapture align 2 %buf) local_unnamed_addr #0 !kernel_arg_addr_space !6 !kernel_arg_access_qual !7 !kernel_arg_type !8 !kernel_arg_base_type !8 !kernel_arg_type_qual !9 !kernel_arg_name !10 !clspv.pod_args_impl !11 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x half] } zeroinitializer)
  %1 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %2 = load i32, ptr addrspace(5) %1, align 16
  %3 = getelementptr { [0 x half] }, ptr addrspace(1) %0, i32 0, i32 0, i32 %2
  %4 = load half, ptr addrspace(1) %3, align 2
  %call1 = tail call spir_func half @_Z4fabsDh(half %4) #2
  store half %call1, ptr addrspace(1) %3, align 2
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(none)
declare !kernel_arg_name !9 spir_func half @_Z4fabsDh(half) local_unnamed_addr #1

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x half] })

attributes #0 = { convergent mustprogress nofree norecurse nounwind willreturn memory(read, argmem: readwrite, inaccessiblemem: none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent mustprogress nofree nounwind willreturn memory(none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind willreturn memory(none) "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!_Z28clspv.entry_point_attributes = !{!5}
!clspv.descriptor.index = !{!6}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 19.0.0git (https://github.com/llvm/llvm-project e651ee98cfcdebd799de0d61eca22b7b1493cc96)"}
!5 = !{!"test_simple", !"kernel"}
!6 = !{i32 1}
!7 = !{!"none"}
!8 = !{!"half*"}
!9 = !{!""}
!10 = !{!"buf"}
!11 = !{i32 2}
