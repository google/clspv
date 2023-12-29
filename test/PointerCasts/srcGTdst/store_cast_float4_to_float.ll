; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(1) %a, i32 0, i32 3
; CHECK: store float %0, ptr addrspace(1) [[gep]]
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b) {
entry:
  %0 = load float, ptr addrspace(1) %b, align 4
  %1 = getelementptr <4 x float>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %1, i32 3
  store float %0, ptr addrspace(1) %arrayidx, align 4
  ret void
}
