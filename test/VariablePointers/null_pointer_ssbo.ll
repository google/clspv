; Issue #1488
; XFAIL: *
; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; Null pointer for SSBO requires VariablePointersStorageBuffer.
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpCapability VariablePointersStorageBuffer
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpExtension "SPV_KHR_variable_pointers"
; CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
; CHECK: OpConstantNull [[ptr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 4 %out, { i32 } %podargs) !clspv.pod_args_impl !14 !kernel_arg_map !15 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = load i32, ptr addrspace(1) null, align 2147483648
  store i32 %2, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!14 = !{i32 2}
!15 = !{!16, !17}
!16 = !{!"out", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!17 = !{!"n", i32 1, i32 1, i32 0, i32 4, !"pod_pushconstant"}

