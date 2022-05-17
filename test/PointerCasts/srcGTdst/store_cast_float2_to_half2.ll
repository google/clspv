; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 %i, 1
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 %i, 1
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x half> %0 to float
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x float>, <2 x float> addrspace(1)* %b, i32 [[shr]], i32 [[and]]
; CHECK: store float [[bitcast]], float addrspace(1)* [[gep]]

define spir_kernel void @foo(<2 x half> addrspace(1)* %a, <2 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <2 x half>, <2 x half> addrspace(1)* %a, align 8
  %1 = bitcast <2 x float> addrspace(1)* %b to <2 x half> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x half>, <2 x half> addrspace(1)* %1, i32 %i
  store <2 x half> %0, <2 x half> addrspace(1)* %arrayidx, align 8
  ret void
}


