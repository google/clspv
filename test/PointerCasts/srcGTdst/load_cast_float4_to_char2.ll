; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 1
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[lshr]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[lshr]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x float>, ptr addrspace(1) %0, i32 [[lshr2]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load float, ptr addrspace(1) [[gep]]
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 1
; CHECK:  [[bitcast:%[^ ]+]] = bitcast float [[load]] to <4 x i8>
; CHECK:  [[shuffle0:%[^ ]+]] = shufflevector <4 x i8> [[bitcast]], <4 x i8> poison, <2 x i32> <i32 0, i32 1>
; CHECK:  [[shuffle1:%[^ ]+]] = shufflevector <4 x i8> [[bitcast]], <4 x i8> poison, <2 x i32> <i32 2, i32 3>
; CHECK:  [[cmp:%[^ ]+]] = icmp eq i32 [[and]], 0
; CHECK:  select i1 [[cmp]], <2 x i8> [[shuffle0]], <2 x i8> [[shuffle1]]

define spir_kernel void @foo(<2 x i8> addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = getelementptr <4 x float>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds <2 x i8>, ptr addrspace(1) %0, i32 %i
  %1 = load <2 x i8>, ptr addrspace(1) %arrayidx, align 8
  store <2 x i8> %1, ptr addrspace(1) %a, align 8
  ret void
}


