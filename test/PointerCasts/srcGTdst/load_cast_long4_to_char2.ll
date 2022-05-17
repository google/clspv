; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 2
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[lshr]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[lshr]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %b, i32 [[lshr2]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load i64, i64 addrspace(1)* [[gep]]
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 3
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i64 [[load]] to <4 x i16>
; CHECK:  [[extract:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 [[and]]
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i16 [[extract]] to <2 x i8>

define spir_kernel void @foo(<2 x i8> addrspace(1)* %a, <4 x i64> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x i64> addrspace(1)* %b to <2 x i8> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x i8>, <2 x i8> addrspace(1)* %0, i32 %i
  %1 = load <2 x i8>, <2 x i8> addrspace(1)* %arrayidx, align 8
  store <2 x i8> %1, <2 x i8> addrspace(1)* %a, align 8
  ret void
}


