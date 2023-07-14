; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %a) !clspv.pod_args_impl !1 {
entry:
  call void @foo(ptr addrspace(1) %a)
  ret void
}

define spir_func void @foo(ptr addrspace(1) %in) {
entry:
  call void @bar(ptr addrspace(1) %in)
  ret void
}

define spir_func void @bar(ptr addrspace(1) %x) {
entry:
  %0 = load i32, ptr addrspace(1) %x
  ret void
}

!1 = !{i32 1}
