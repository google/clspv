; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:  [[shuffle0:%[^ ]+]] = shufflevector <4 x i16> %0, <4 x i16> poison, <2 x i32> <i32 0, i32 1>
; CHECK:  [[shuffle1:%[^ ]+]] = shufflevector <4 x i16> %0, <4 x i16> poison, <2 x i32> <i32 2, i32 3>
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <2 x i16> [[shuffle0]] to float
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <2 x i16> [[shuffle1]] to float
; CHECK:  [[gep:%[^ ]+]] = getelementptr float, float addrspace(1)* %a, i32 [[shl]]
; CHECK:  store float [[bitcast0]], float addrspace(1)* [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[shl]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr float, float addrspace(1)* %a, i32 [[add]]
; CHECK:  store float [[bitcast1]], float addrspace(1)* [[gep]]

define spir_kernel void @foo(float addrspace(1)* %a, <4 x i16> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <4 x i16>, <4 x i16> addrspace(1)* %b, align 8
  %1 = bitcast float addrspace(1)* %a to <4 x i16> addrspace(1)*
  %arrayidx = getelementptr inbounds <4 x i16>, <4 x i16> addrspace(1)* %1, i32 %i
  store <4 x i16> %0, <4 x i16> addrspace(1)* %arrayidx, align 8
  ret void
}


