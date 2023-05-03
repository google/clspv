; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[alloca:%[^ ]+]] = alloca [4 x <2 x i8>], align 2
; CHECK:  [[load:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) %b, align 2
; CHECK:  [[gep:%[^ ]+]] = getelementptr [4 x <2 x i8>], ptr [[alloca]], i32 0, i32 0
; CHECK:  store <2 x i8> [[load]], ptr [[gep]], align 2

define spir_kernel void @foo(ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = alloca <2 x float>, align 8
  %1 = load <2 x i8>, ptr addrspace(1) %b, align 2
  store <2 x i8> %1, ptr %0, align 2
  ret void
}
