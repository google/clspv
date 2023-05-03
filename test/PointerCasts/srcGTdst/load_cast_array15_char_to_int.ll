; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[alloca:%[^ ]+]] = alloca [15 x i8], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [15 x i8], ptr [[alloca]], i32 0
; CHECK:  load [15 x i8], ptr [[gep]], align 1
; ...
; CHECK:  [[bitcast:%[^ ]+]] = bitcast <4 x i8> {{.*}} to i32
; CHECK:  store i32 [[bitcast]], ptr addrspace(1) %b, align 4

define spir_kernel void @foo(ptr addrspace(1) %b) {
entry:
  %alloca = alloca [15 x i8], align 1
  %0 = load i32, ptr %alloca, align 4
  store i32 %0, ptr addrspace(1) %b, align 4
  ret void
}
