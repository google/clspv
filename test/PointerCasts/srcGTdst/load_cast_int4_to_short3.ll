; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[shl]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %b, i32 [[lshr]], i32 [[and]]
; CHECK:  [[load0:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %b, i32 [[lshr]], i32 [[add]]
; CHECK:  [[load1:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[insert0:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[load0]], i32 0
; CHECK:  [[insert1:%[^ ]+]] = insertelement <2 x i32> [[insert0]], i32 [[load1]], i32 1
; CHECK:  [[bitcast:%[^ ]+]] = bitcast <2 x i32> [[insert1]] to <4 x i16>
; CHECK:  shufflevector <4 x i16> [[bitcast]], <4 x i16> poison, <3 x i32> <i32 0, i32 1, i32 2>

define spir_kernel void @foo(<3 x i16> addrspace(1)* %a, <4 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x i32> addrspace(1)* %b to <3 x i16> addrspace(1)*
  %arrayidx = getelementptr inbounds <3 x i16>, <3 x i16> addrspace(1)* %0, i32 %i
  %1 = load <3 x i16>, <3 x i16> addrspace(1)* %arrayidx, align 8
  store <3 x i16> %1, <3 x i16> addrspace(1)* %a, align 8
  ret void
}


