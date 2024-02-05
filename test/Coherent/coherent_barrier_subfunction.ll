; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env vulkan1.0
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[var]] Binding 0
; CHECK: OpDecorate [[var]] Coherent

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func void @bar() {
entry:
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72)
  ret void
}

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture align 4 %data)!clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = load i32, ptr addrspace(1) %1, align 4
  tail call spir_func void @bar()
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  store i32 %2, ptr addrspace(1) %3, align 4
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!14 = !{i32 2}

