; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.s] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x { [4 x <2 x i32>] }] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x <4 x i32>] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.s = type { i32, float }

define spir_kernel void @test(ptr addrspace(1) %a, ptr addrspace(1) %b, ptr addrspace(1) %c) !clspv.pod_args_impl !1 {
entry:
  %0 = load %struct.s, ptr addrspace(1) %a
  %1 = load { [4 x <2 x i32>] }, ptr addrspace(1) %b
  %2 = load <4 x i32>, ptr addrspace(1) %c
  ret void
}

!1 = !{i32 1}

