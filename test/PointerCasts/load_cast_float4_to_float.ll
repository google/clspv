; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 %i, 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[shr]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load <4 x float>, <4 x float> addrspace(1)* [[gep]]
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 %i, 3
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> [[ld0]], i32 [[and]]
define spir_kernel void @foo(float addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x float> addrspace(1)* %b to float addrspace(1)*
  %arrayidx = getelementptr inbounds float, float addrspace(1)* %0, i32 %i
  %1 = load float, float addrspace(1)* %arrayidx, align 8
  store float %1, float addrspace(1)* %a, align 8
  ret void
}


