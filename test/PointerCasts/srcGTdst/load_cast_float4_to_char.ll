; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 2
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[lshr]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[lshr]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[lshr2]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load float, float addrspace(1)* [[gep]]
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 3
; CHECK:  [[bitcast:%[^ ]+]] = bitcast float [[load]] to <4 x i8>
; CHECK:  extractelement <4 x i8> [[bitcast]], i32 [[and]]

define spir_kernel void @foo(i8 addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x float> addrspace(1)* %b to i8 addrspace(1)*
  %arrayidx = getelementptr inbounds i8, i8 addrspace(1)* %0, i32 %i
  %1 = load i8, i8 addrspace(1)* %arrayidx, align 8
  store i8 %1, i8 addrspace(1)* %a, align 8
  ret void
}


