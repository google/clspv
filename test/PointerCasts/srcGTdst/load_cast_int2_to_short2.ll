; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i32:32-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 1
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %0, i32 [[lshr]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]]
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i32 [[load]] to <2 x i16>

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x i32>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds <2 x i16>, ptr addrspace(1) %0, i32 %i
  %1 = load <2 x i16>, ptr addrspace(1) %arrayidx, align 8
  store <2 x i16> %1, ptr addrspace(1) %a, align 8
  ret void
}


