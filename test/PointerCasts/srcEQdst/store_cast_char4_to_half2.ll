; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[ld:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* %b
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x half> [[ld]] to <4 x i8>
; CHECK: [[gep:%[^ ]+]] = getelementptr <4 x i8>, <4 x i8> addrspace(1)* %a, i32 %i
; CHECK: store <4 x i8> [[bitcast]], <4 x i8> addrspace(1)* [[gep]]

define spir_kernel void @foo(<4 x i8> addrspace(1)* %a, <2 x half> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <2 x half>, <2 x half> addrspace(1)* %b, align 8
  %1 = bitcast <4 x i8> addrspace(1)* %a to <2 x half> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x half>, <2 x half> addrspace(1)* %1, i32 %i
  store <2 x half> %0, <2 x half> addrspace(1)* %arrayidx, align 8
  ret void
}

