; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[gep:%[^ ]+]] = getelementptr i64, i64 addrspace(1)* %b, i32 %i
; CHECK:  [[load:%[^ ]+]] = load i64, i64 addrspace(1)* [[gep]]
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i64 [[load]] to <4 x i16>
; CHECK:  shufflevector <4 x i16> [[bitcast]], <4 x i16> poison, <3 x i32> <i32 0, i32 1, i32 2>

define spir_kernel void @foo(<3 x i16> addrspace(1)* %a, i64 addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast i64 addrspace(1)* %b to <3 x i16> addrspace(1)*
  %arrayidx = getelementptr inbounds <3 x i16>, <3 x i16> addrspace(1)* %0, i32 %i
  %1 = load <3 x i16>, <3 x i16> addrspace(1)* %arrayidx, align 8
  store <3 x i16> %1, <3 x i16> addrspace(1)* %a, align 8
  ret void
}


