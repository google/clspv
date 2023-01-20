; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %0, i32 [[shl]]
; CHECK: [[ld0:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %0, i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %0, i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %0, i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]]

; CHECK: [[ret0:%[^ ]+]] = insertelement <4 x i8> undef, i8 [[ld0]], i32 0
; CHECK: [[ret1:%[^ ]+]] = insertelement <4 x i8> [[ret0]], i8 [[ld1]], i32 1
; CHECK: [[ret2:%[^ ]+]] = insertelement <4 x i8> [[ret1]], i8 [[ld2]], i32 2
; CHECK: [[ret3:%[^ ]+]] = insertelement <4 x i8> [[ret2]], i8 [[ld3]], i32 3
; CHECK: bitcast <4 x i8> [[ret3]] to <2 x half>
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:  
  %0 = getelementptr i8, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <2 x half>, ptr addrspace(1) %0, i32 %i
  %1 = load <2 x half>, ptr addrspace(1) %arrayidx, align 8
  store <2 x half> %1, ptr addrspace(1) %b, align 8
  ret void
}

