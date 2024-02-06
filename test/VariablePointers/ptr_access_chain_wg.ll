; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; The OpPtrAccessChain requires VariablePointers for Workgorup.
; CHECK-NOT: OpCapability VariablePointersStorageBuffer
; CHECK: OpCapability VariablePointers
; CHECK-NOT: StorageBuffer
; CHECK: OpExtension "SPV_KHR_variable_pointers"
; CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
; CHECK: OpPtrAccessChain [[ptr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(3) nocapture readonly align 4 %in, ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !19 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x i32] zeroinitializer)
  %1 = getelementptr [0 x i32], ptr addrspace(3) %0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 1, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = getelementptr i32, ptr addrspace(3) %1, i32 1
  %5 = load i32, ptr addrspace(3) %4, align 4
  store i32 %5, ptr addrspace(1) %3, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x i32])

!19 = !{i32 2}

