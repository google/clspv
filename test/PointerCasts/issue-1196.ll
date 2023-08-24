; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[alloca:%[^ ]+]] = alloca [196 x i8], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [196 x i8], ptr [[alloca]], i32 0, i32 64
; CHECK:  store i8 %val, ptr [[gep]], align 1

define dso_local spir_kernel void @kernel(i8 %val) {
entry:
  %alloca = alloca { [8 x i64], [16 x i64], i32 }, align 16
  %gep = getelementptr { [8 x i64], [16 x i64], i32 }, ptr %alloca, i32 0, i32 1, i32 0
  store i8 %val, ptr %gep, align 1
  ret void
}
