; RUN: clspv-opt --passes=auto-pod-args -cl-std=CL2.0 %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; get_enqueued_local_size prevents using push constants.

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out, i32 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 {{[013]}}}
define spir_kernel void @foo(ptr addrspace(1) %out, i32 %pod) {
entry:
  %gep0 = getelementptr i32, ptr addrspace(1) %out, i32 0
  store i32 %pod, ptr addrspace(1) %gep0
  %gep1 = getelementptr i32, ptr addrspace(1) %out, i32 1
  %enqueued = call i32 @_Z23get_enqueued_local_sizej(i32 0)
  store i32 %enqueued, ptr addrspace(1) %gep1
  ret void
}

declare i32 @_Z23get_enqueued_local_sizej(i32)
