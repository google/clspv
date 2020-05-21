; RUN: clspv-opt -AutoPodArgs -cl-std=CL2.0 %s -o %t.ll -max-pushconstant-size=4
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s = type { i8, [2 x i8], i32 }

; Max push constant size prevents push constants and layout prevents UBOs.

; CHECK: define spir_kernel void @foo(i32 addrspace(1)* %out, %s %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 0}
define spir_kernel void @foo(i32 addrspace(1)* %out, %s %pod) {
entry:
  %ex = extractvalue %s %pod, 2
  %gep0 = getelementptr i32, i32 addrspace(1)* %out, i32 0
  store i32 %ex, i32 addrspace(1)* %gep0
  %gep1 = getelementptr i32, i32 addrspace(1)* %out, i32 1
  %enqueued = call i32 @_Z23get_enqueued_local_sizej(i32 0)
  store i32 %enqueued, i32 addrspace(1)* %gep1
  ret void
}

declare i32 @_Z23get_enqueued_local_sizej(i32)

