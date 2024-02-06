; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; Passing SSBO to function call requires VariablePointersStorageBuffer.
; SSBO args do not require memory object declarations.
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpCapability VariablePointersStorageBuffer
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpExtension "SPV_KHR_variable_pointers"
; CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
; CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
; CHECK: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[uint_0]] [[uint_1]]
; CHECK-NEXT: OpFunctionCall [[uint]] {{.*}} [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func i32 @bar(ptr addrspace(1) nocapture readonly %x) {
entry:
  %0 = load i32, ptr addrspace(1) %x, align 4
  ret i32 %0
}

define spir_kernel void @foo(ptr addrspace(1) nocapture readonly align 4 %in, ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !16 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %2 = getelementptr { [0 x i32] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %call.i = tail call spir_func i32 @bar(ptr addrspace(1) %3)
  store i32 %call.i, ptr addrspace(1) %2, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!16 = !{i32 2}

