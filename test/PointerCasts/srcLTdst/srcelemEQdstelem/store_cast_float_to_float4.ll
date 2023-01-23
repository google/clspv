; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 2
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> %0, i64 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> %0, i64 1
; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> %0, i64 2
; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> %0, i64 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %1, i32 [[shl]]
; CHECK: store float [[ex0]], ptr addrspace(1) [[gep]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %1, i32 [[add1]]
; CHECK: store float [[ex1]], ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = add i32 [[add1]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %1, i32 [[add2]]
; CHECK: store float [[ex2]], ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %1, i32 [[add3]]
; CHECK: store float [[ex3]], ptr addrspace(1) [[gep]]
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load <4 x float>, ptr addrspace(1) %b, align 8
  %1 = getelementptr float, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <4 x float>, ptr addrspace(1) %1, i32 %i
  store <4 x float> %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

