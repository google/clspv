; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 3
; CHECK: [[and:%[^ ]+]] = and i32 [[shl]], 7
; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %b, i32 [[shr]], i32 [[and]]
; CHECK: [[ld0:%[^ ]+]] = load half, half addrspace(1)* [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %b, i32 [[shr]], i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load half, half addrspace(1)* [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %b, i32 [[shr]], i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load half, half addrspace(1)* [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %b, i32 [[shr]], i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load half, half addrspace(1)* [[gep]]
; CHECK: [[in0:%[^ ]+]] = insertelement <4 x half> undef, half [[ld0]], i32 0
; CHECK: [[in1:%[^ ]+]] = insertelement <4 x half> [[in0]], half [[ld1]], i32 1
; CHECK: [[in2:%[^ ]+]] = insertelement <4 x half> [[in1]], half [[ld2]], i32 2
; CHECK: [[in:%[^ ]+]] = insertelement <4 x half> [[in2]], half [[ld3]], i32 3
; CHECK: bitcast <4 x half> [[in]] to <2 x i32>

define spir_kernel void @foo(<2 x i32> addrspace(1)* %a, [8 x half] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast [8 x half] addrspace(1)* %b to <2 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x i32>, <2 x i32> addrspace(1)* %0, i32 %i
  %1 = load <2 x i32>, <2 x i32> addrspace(1)* %arrayidx, align 8
  store <2 x i32> %1, <2 x i32> addrspace(1)* %a, align 8
  ret void
}


