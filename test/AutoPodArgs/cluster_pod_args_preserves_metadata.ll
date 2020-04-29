; RUN: clspv-opt -ClusterPodKernelArgumentsPass %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; The pod args impl metadata needs to be copied onto the wrapper function.

; CHECK: define spir_kernel void @foo(i32 addrspace(1)* %out, { i32, i32 } %podargs) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 2}
define spir_kernel void @foo(i32 addrspace(1)* %out, i32 %pod1, i32 %pod2) !clspv.pod_args_impl !0 {
entry:
  %gep0 = getelementptr i32, i32 addrspace(1)* %out, i32 0
  store i32 %pod1, i32 addrspace(1)* %gep0
  %gep1 = getelementptr i32, i32 addrspace(1)* %out, i32 1
  store i32 %pod2, i32 addrspace(1)* %gep1
  ret void
}

!0 = !{i32 2}
