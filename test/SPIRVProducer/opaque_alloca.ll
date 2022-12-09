; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv -spv-version=1.5 --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.3 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Function [[float]]
; CHECK: OpVariable [[ptr]] Function
; CHECK: OpVariable [[ptr]] Function

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @IsTininessDetectedBeforeRounding(ptr addrspace(1) nocapture writeonly align 4 %out) !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %1 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %a = alloca float, align 4
  %b = alloca float, align 4
  store volatile float 0x3810000020000000, ptr %a, align 4
  store volatile float 0x3FEFFFFFC0000000, ptr %b, align 4
  %a.0.a.0.a.0.a.0.a.0. = load volatile float, ptr %a, align 4
  %b.0.b.0.b.0.b.0.b.0. = load volatile float, ptr %b, align 4
  %mul = fmul float %a.0.a.0.a.0.a.0.a.0., %b.0.b.0.b.0.b.0.b.0.
  store float %mul, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x float] })

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2}
!llvm.ident = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!clspv.descriptor.index = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 3, i32 0}
!2 = !{i32 1, i32 2}
!3 = !{!"clang version 16.0.0 (https://github.com/llvm/llvm-project 50882b4daf77b9d93e025f804b0855c94a83f237)"}
!4 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!5 = !{i32 1}
!6 = !{!"none"}
!7 = !{!"float*"}
!8 = !{!""}
!9 = !{i32 2}

