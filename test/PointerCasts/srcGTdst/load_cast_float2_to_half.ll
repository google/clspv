; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 1
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[lshr]], 1
; CHECK:  [[and:%[^ ]+]] = and i32 [[lshr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x float>, ptr addrspace(1) %0, i32 [[lshr2]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load float, ptr addrspace(1) [[gep]]
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 1
; CHECK:  [[bitcast:%[^ ]+]] = bitcast float [[load]] to <2 x half>
; CHECK:  extractelement <2 x half> [[bitcast]], i32 [[and]]

define spir_kernel void @foo(half addrspace(1)* %a, <2 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = getelementptr <2 x float>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds half, ptr addrspace(1) %0, i32 %i
  %1 = load half, ptr addrspace(1) %arrayidx, align 8
  store half %1, ptr addrspace(1) %a, align 8
  ret void
}


