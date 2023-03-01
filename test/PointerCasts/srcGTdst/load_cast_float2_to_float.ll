; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x float>, ptr addrspace(1) %b, i32 0, i32 0
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr inbounds float, ptr addrspace(1) [[gep]], i32 %i
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[gep2]]
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x float>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %b, i32 %i
  %1 = load float, ptr addrspace(1) %arrayidx, align 4
  store float %1, ptr addrspace(1) %a, align 4
  ret void
}
