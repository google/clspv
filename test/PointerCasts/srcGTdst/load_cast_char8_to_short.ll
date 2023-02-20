; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[shl]], 3
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl]], 7
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i8], ptr addrspace(1) %0, i32 [[lshr]], i32 [[and]]
; CHECK:  [[ld0:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i8], ptr addrspace(1) %0, i32 [[lshr]], i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]
; CHECK:  [[insert0:%[^ ]+]] = insertelement <2 x i8> poison, i8 [[ld0]], i32 0
; CHECK:  [[insert1:%[^ ]+]] = insertelement <2 x i8> [[insert0]], i8 [[ld1]], i32 1
; CHECK:  bitcast <2 x i8> [[insert1]] to i16

define spir_kernel void @foo(i16 addrspace(1)* %a, [8 x i8] addrspace(1)* %b, i32 %i) {
entry:
  %0 = getelementptr [8 x i8], ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds i16, ptr addrspace(1) %0, i32 %i
  %1 = load i16, ptr addrspace(1) %arrayidx, align 8
  store i16 %1, ptr addrspace(1) %a, align 8
  ret void
}


