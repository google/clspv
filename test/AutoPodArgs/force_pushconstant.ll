; RUN: clspv-opt --passes=auto-pod-args -pod-pushconstant %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out, i32 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 2}
define spir_kernel void @foo(ptr addrspace(1) %out, i32 %pod) {
entry:
  store i32 %pod, ptr addrspace(1) %out
  ret void
}

