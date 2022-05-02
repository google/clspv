; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 %i, 2
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 %i, 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %a, i32 [[shr]], i32 [[and]]
; CHECK: store float %0, float addrspace(1)* [[gep]]
define spir_kernel void @foo(<4 x float> addrspace(1)* %a, float addrspace(1)* %b, i32 %i) {
entry:
  %0 = load float, float addrspace(1)* %b, align 4
  %1 = bitcast <4 x float> addrspace(1)* %a to float addrspace(1)*
  %arrayidx = getelementptr inbounds float, float addrspace(1)* %1, i32 %i
  store float %0, float addrspace(1)* %arrayidx, align 4
  ret void
}
