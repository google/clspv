; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: foo1
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 %i, i32 %i

define spir_kernel void @foo1(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 %i
  %1 = getelementptr <4 x i32>, ptr %0, i32 0, i32 %i
  ret void
}

; CHECK: foo2
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 2, i32 %i

define spir_kernel void @foo2(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 2
  %1 = getelementptr <4 x i32>, ptr %0, i32 0, i32 %i
  ret void
}

; CHECK: foo3
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 2, i32 %i

define spir_kernel void @foo3(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 0
  %1 = getelementptr <4 x i32>, ptr %0, i32 2, i32 %i
  ret void
}

; CHECK: foo4
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 3, i32 %i

define spir_kernel void @foo4(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 2
  %1 = getelementptr <4 x i32>, ptr %0, i32 1, i32 %i
  ret void
}

; CHECK: foo5
; CHECK-NEXT: entry
; CHECK-NEXT: [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK-NEXT: [[add:%[^ ]+]] = add i32 [[shl]], 4
; CHECK-NEXT: [[lshr:%[^ ]+]] = lshr i32 [[add]], 3
; CHECK-NEXT: [[and:%[^ ]+]] = and i32 [[add]], 7
; CHECK-NEXT: [[lshr2:%[^ ]+]] = lshr i32 [[and]], 2
; CHECK-NEXT: [[and2:%[^ ]+]] = and i32 [[and]], 3
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 [[lshr]], i32 [[lshr2]], i32 [[and2]], i32 %i

define spir_kernel void @foo5(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 2
  %1 = getelementptr <4 x i32>, ptr %0, i32 2, i32 %i
  ret void
}

; CHECK: foo6
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [1 x <4 x i32>], ptr %a, i32 0, i32 4, i32 %i

define spir_kernel void @foo6(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [1 x <4 x i32>], ptr %a, i32 0, i32 2
  %1 = getelementptr <4 x i32>, ptr %0, i32 2, i32 %i
  ret void
}

; CHECK: foo7
; CHECK-NEXT: entry
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 1, i32 2, i32 %i

define spir_kernel void @foo7(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 0, i32 3
  %1 = getelementptr <4 x i32>, ptr %0, i32 3, i32 %i
  ret void
}

; CHECK: foo8
; CHECK-NEXT: entry
; CHECK-NEXT: [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK-NEXT: [[add1:%[^ ]+]] = add i32 [[shl]], %i
; CHECK-NEXT: [[add2:%[^ ]+]] = add i32 [[add1]], 3
; CHECK-NEXT: [[lshr:%[^ ]+]] = lshr i32 [[add2]], 3
; CHECK-NEXT: [[and:%[^ ]+]] = and i32 [[add2]], 7
; CHECK-NEXT: [[lshr2:%[^ ]+]] = lshr i32 [[and]], 2
; CHECK-NEXT: [[and2:%[^ ]+]] = and i32 [[and]], 3
; CHECK-NEXT: getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 [[lshr]], i32 [[lshr2]], i32 [[and2]], i32 %i

define spir_kernel void @foo8(ptr %a, i32 %i) {
entry:
  %0 = getelementptr [2 x [4 x <4 x i32>]], ptr %a, i32 0, i32 %i, i32 3
  %1 = getelementptr <4 x i32>, ptr %0, i32 %i, i32 %i
  ret void
}
