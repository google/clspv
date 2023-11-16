; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[mul:%[^ ]+]] = mul i32 %i, 68
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %source, i32 [[mul]]
; CHECK:  load i8, ptr addrspace(1) [[gep]], align 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.pw = type { i32, [64 x i8] }

define spir_kernel void @foo(ptr addrspace(1) %source, i32 %i) {
entry:
  %gep = getelementptr inbounds { [0 x %struct.pw] }, ptr addrspace(1) %source, i32 %i
  %load = load i8, ptr addrspace(1) %gep, align 1
  ret void
}
