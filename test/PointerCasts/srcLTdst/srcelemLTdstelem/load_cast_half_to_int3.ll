; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 3
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[shl]]
; CHECK: [[ld0:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add4]]
; CHECK: [[ld4:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add5]]
; CHECK: [[ld5:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add6]]
; CHECK: [[ld6:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr half, ptr addrspace(1) %0, i32 [[add7]]
; CHECK: [[ld7:%[^ ]+]] = load half, ptr addrspace(1) [[gep]]

; CHECK: [[in0:%[^ ]+]] = insertelement <4 x half> poison, half [[ld0]], i32 0
; CHECK: [[in1:%[^ ]+]] = insertelement <4 x half> [[in0]], half [[ld1]], i32 1
; CHECK: [[in2:%[^ ]+]] = insertelement <4 x half> [[in1]], half [[ld2]], i32 2
; CHECK: [[in3:%[^ ]+]] = insertelement <4 x half> [[in2]], half [[ld3]], i32 3
; CHECK: [[in4:%[^ ]+]] = insertelement <4 x half> poison, half [[ld4]], i32 0
; CHECK: [[in5:%[^ ]+]] = insertelement <4 x half> [[in4]], half [[ld5]], i32 1
; CHECK: [[in6:%[^ ]+]] = insertelement <4 x half> [[in5]], half [[ld6]], i32 2
; CHECK: [[in7:%[^ ]+]] = insertelement <4 x half> [[in6]], half [[ld7]], i32 3

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x half> [[in3]] to <2 x i32>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x half> [[in7]] to <2 x i32>

; CHECK: [[shuffle:%[^ ]+]] = shufflevector <2 x i32> [[bitcast0]], <2 x i32> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: shufflevector <4 x i32> [[shuffle]], <4 x i32> poison, <3 x i32> <i32 0, i32 1, i32 2>

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr half, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <3 x i32>, ptr addrspace(1) %0, i32 %i
  %1 = load <3 x i32>, ptr addrspace(1) %arrayidx, align 8
  store <3 x i32> %1, ptr addrspace(1) %b, align 8
  ret void
}

