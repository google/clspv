; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 2
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, ptr addrspace(1) %0, i32 [[shr]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load <2 x i32>, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, ptr addrspace(1) %0, i32 [[add]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load <2 x i32>, ptr addrspace(1) [[gep]]
; CHECK: [[shuffle:%[a-zA_Z0-9_.]+]] = shufflevector <2 x i32> [[ld0]], <2 x i32> [[ld1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: bitcast <4 x i32> [[shuffle]] to <4 x float>
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x i32>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <4 x float>, ptr addrspace(1) %0, i32 %i
  %1 = load <4 x float>, ptr addrspace(1) %arrayidx, align 16
  store <4 x float> %1, ptr addrspace(1) %b, align 16
  ret void
}

