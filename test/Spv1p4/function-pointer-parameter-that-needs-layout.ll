; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpTypePointer StorageBuffer %uint
; CHECK-NOT: OpTypePointer StorageBuffer %uint

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func void @func(i32 addrspace(1)* nocapture %ptr) local_unnamed_addr {
entry:
  store i32 42, i32 addrspace(1)* %ptr, align 4
  ret void
}

define dso_local spir_kernel void @test(i32 addrspace(1)* nocapture %out) local_unnamed_addr !clspv.pod_args_impl !8 {
entry:
  %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 3
  tail call spir_func void @func(i32 addrspace(1)* %1)
  ret void
}

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!clspv.descriptor.index = !{!4}

!4 = !{i32 1}
!8 = !{i32 2}
