; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env vulkan1.0
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpDecorate [[data:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[data]] Binding 0
; CHECK: OpDecorate [[data]] Coherent
; CHECK: OpDecorate [[x:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[x]] Binding 1
; CHECK-NOT: OpDecorate [[x]] Coherent

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture align 4 %data, ptr addrspace(1) nocapture writeonly align 4 %x) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %2 = getelementptr { [0 x float] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %4 = load i32, ptr addrspace(1) %3, align 1
  %conv = sitofp i32 %4 to float
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72) #3
  %5 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %call = tail call spir_func float @_Z5frexpfPU3AS1i(float %conv, ptr addrspace(1) %5)
  store float %call, ptr addrspace(1) %2, align 4
  ret void
}

declare dso_local spir_func float @_Z5frexpfPU3AS1i(float noundef, ptr addrspace(1) nocapture noundef writeonly)

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x float] })

!14 = !{i32 2}

