; RUN: clspv-opt --passes=auto-pod-args %s -o %t.ll -no-8bit-storage=pushconstant
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s1 = type { i8 }
%s2 = type { <4 x i8> }

; CHECK: define spir_kernel void @foo(i8 addrspace(1)* %out, i8 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
define spir_kernel void @foo(i8 addrspace(1)* %out, i8 %pod) {
entry:
  %gep0 = getelementptr i8, i8 addrspace(1)* %out, i32 0
  store i8 %pod, i8 addrspace(1)* %gep0
  ret void
}

; CHECK: define spir_kernel void @bar(i8 addrspace(1)* %out, %s1 %pod) !clspv.pod_args_impl [[MD]]
define spir_kernel void @bar(i8 addrspace(1)* %out, %s1 %pod) {
entry:
  %gep0 = getelementptr i8, i8 addrspace(1)* %out, i32 0
  %ex = extractvalue %s1 %pod, 0
  store i8 %ex, i8 addrspace(1)* %gep0
  ret void
}

; CHECK: define spir_kernel void @baz(i8 addrspace(1)* %out, %s2 %pod) !clspv.pod_args_impl [[MD]]
define spir_kernel void @baz(i8 addrspace(1)* %out, %s2 %pod) {
entry:
  %gep0 = getelementptr i8, i8 addrspace(1)* %out, i32 0
  %ex = extractvalue %s2 %pod, 0
  %ex2 = extractelement <4 x i8> %ex, i32 3
  store i8 %ex2, i8 addrspace(1)* %gep0
  ret void
}

; CHECK: [[MD]] = !{i32 {{[[013]}}}


