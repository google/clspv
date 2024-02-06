; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpCapability VariablePointers

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(3) nocapture readonly align 4 %in, ptr addrspace(1) nocapture writeonly align 4 %out, i32 %a, i32 %b, i32 %c) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x i32] zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 1, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %2 = getelementptr { [0 x i32] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0
  %3 = call ptr addrspace(6) @_Z14clspv.resource.1(i32 0, i32 1, i32 4, i32 2, i32 1, i32 0, { i32 } zeroinitializer)
  %4 = getelementptr { i32 }, ptr addrspace(6) %3, i32 0, i32 0
  %5 = load i32, ptr addrspace(6) %4, align 4
  %6 = call ptr addrspace(6) @_Z14clspv.resource.2(i32 0, i32 2, i32 4, i32 3, i32 2, i32 0, { i32 } zeroinitializer)
  %7 = getelementptr { i32 }, ptr addrspace(6) %6, i32 0, i32 0
  %8 = load i32, ptr addrspace(6) %7, align 4
  %9 = call ptr addrspace(6) @_Z14clspv.resource.3(i32 0, i32 3, i32 4, i32 4, i32 3, i32 0, { i32 } zeroinitializer)
  %10 = getelementptr { i32 }, ptr addrspace(6) %9, i32 0, i32 0
  %11 = load i32, ptr addrspace(6) %10, align 4
  %cmp = icmp eq i32 %5, 0
  %b.c = select i1 %cmp, ptr addrspace(6) %7, ptr addrspace(6) %4
  %ld = load i32, ptr addrspace(6) %b.c, align 4
  store i32 %ld, ptr addrspace(1) %2, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(6) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { i32 })

declare ptr addrspace(6) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { i32 })

declare ptr addrspace(6) @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { i32 })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x i32])

!8 = !{i32 1}

