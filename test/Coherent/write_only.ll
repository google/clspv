; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; |data| is only written so it is not marked as Coherent.
; CHECK-NOT: OpDecorate {{.*}} Coherent

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 4 %data, ptr addrspace(3) nocapture readonly align 4 %l) !clspv.pod_args_impl !17 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x i32] zeroinitializer)
  %1 = getelementptr [0 x i32], ptr addrspace(3) %0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = load i32, ptr addrspace(3) %1, align 4
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72)
  store i32 %4, ptr addrspace(1) %3, align 4
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x i32])

!17 = !{i32 2}

