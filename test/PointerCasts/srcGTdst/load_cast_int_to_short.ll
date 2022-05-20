; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i32:32-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, i32 addrspace(1)* %b, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 1
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i32 [[load]] to <2 x i16>
; CHECK:  extractelement <2 x i16> [[bitcast]], i32 [[and]]

define spir_kernel void @foo(i16 addrspace(1)* %a, i32 addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast i32 addrspace(1)* %b to i16 addrspace(1)*
  %arrayidx = getelementptr inbounds i16, i16 addrspace(1)* %0, i32 %i
  %1 = load i16, i16 addrspace(1)* %arrayidx, align 8
  store i16 %1, i16 addrspace(1)* %a, align 8
  ret void
}


