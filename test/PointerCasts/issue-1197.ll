; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[alloca:%[^ ]+]] = alloca [64 x i8], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [64 x i8], ptr [[alloca]], i32 0, i32 0
; CHECK:  store i8 0, ptr [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [64 x i8], ptr [[alloca]], i32 0, i32 1
; CHECK:  store i8 0, ptr [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [64 x i8], ptr [[alloca]], i32 0, i32 2
; CHECK:  store i8 0, ptr [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [64 x i8], ptr [[alloca]], i32 0, i32 3
; CHECK:  store i8 0, ptr [[gep]], align 1

define dso_local spir_kernel void @kernel() {
entry:
  %alloca = alloca [64 x i8], align 1
  store i32 0, ptr %alloca, align 4
  ret void
}
