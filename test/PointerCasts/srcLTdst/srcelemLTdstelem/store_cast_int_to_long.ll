; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[bitcast:%[a-zA-Z0-9_.]+]] = bitcast i64 %s to <2 x i32>
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[bitcast]], i64 0
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[bitcast]], i64 1
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %0, i32 0
; CHECK: store i32 [[trunc0]], ptr addrspace(1) [[gep0]]
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %0, i32 1
; CHECK: store i32 [[trunc1]], ptr addrspace(1) [[gep1]]
define spir_kernel void @foo(ptr addrspace(1) %a, i64 %s) {
entry:
  %0 = getelementptr i32, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds i64, ptr addrspace(1) %0, i32 0
  store i64 %s, ptr addrspace(1) %arrayidx, align 2
  ret void
}

