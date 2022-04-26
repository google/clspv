; RUN: clspv-opt --passes=auto-pod-args -max-pushconstant-size=1 %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; max push constant size prevents push constants.

; CHECK: define spir_kernel void @foo(i32 addrspace(1)* %out, i32 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 1}
define spir_kernel void @foo(i32 addrspace(1)* %out, i32 %pod) {
entry:
  %gep0 = getelementptr i32, i32 addrspace(1)* %out, i32 0
  store i32 %pod, i32 addrspace(1)* %gep0
  ret void
}

