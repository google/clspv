; RUN: clspv-opt -AutoPodArgs %s -o %t.ll -no-16bit-storage=pushconstant
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s1 = type { i16 }
%s2 = type { <4 x half> }

; CHECK: define spir_kernel void @foo(i16 addrspace(1)* %out, i16 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
define spir_kernel void @foo(i16 addrspace(1)* %out, i16 %pod) {
entry:
  %gep0 = getelementptr i16, i16 addrspace(1)* %out, i32 0
  store i16 %pod, i16 addrspace(1)* %gep0
  ret void
}

; CHECK: define spir_kernel void @bar(i16 addrspace(1)* %out, %s1 %pod) !clspv.pod_args_impl [[MD]]
define spir_kernel void @bar(i16 addrspace(1)* %out, %s1 %pod) {
entry:
  %gep0 = getelementptr i16, i16 addrspace(1)* %out, i32 0
  %ex = extractvalue %s1 %pod, 0
  store i16 %ex, i16 addrspace(1)* %gep0
  ret void
}

; CHECK: define spir_kernel void @baz(half addrspace(1)* %out, %s2 %pod) !clspv.pod_args_impl [[MD]]
define spir_kernel void @baz(half addrspace(1)* %out, %s2 %pod) {
entry:
  %gep0 = getelementptr half, half addrspace(1)* %out, i32 0
  %ex = extractvalue %s2 %pod, 0
  %ex2 = extractelement <4 x half> %ex, i32 3
  store half %ex2, half addrspace(1)* %gep0
  ret void
}

; CHECK: [[MD]] = !{i32 1}
