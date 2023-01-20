; RUN: clspv-opt --passes=auto-pod-args %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; The array in the struct prevents use of push constants.

%struct = type { [4 x i32] }

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out, %struct %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 {{[013]}}}
define spir_kernel void @foo(ptr addrspace(1) %out, %struct %pod) {
entry:
  %gep0 = getelementptr i32, ptr addrspace(1) %out, i32 0
  %ex = extractvalue %struct %pod, 0, 1
  store i32 %ex, ptr addrspace(1) %gep0
  ret void
}

