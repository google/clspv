; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[alloca:%[^ ]+]] = alloca [32 x i8], align 1
; CHECK: getelementptr [8 x i8], ptr [[alloca]], i32 0, i32 7

define dso_local spir_kernel void @kernel() {
entry:
  %0 = alloca [4 x i64], align 8
  %1 = getelementptr [8 x i8], ptr %0, i32 0, i32 7
  ret void
}
