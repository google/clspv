; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: [[extract0:%[^ ]+]] = extractelement <4 x i32> %vector, i32 0
; CHECK: [[extract1:%[^ ]+]] = extractelement <4 x i32> %vector, i32 1
; CHECK: [[add0:%[^ ]+]] = add i32 [[extract0]], [[extract1]]
; CHECK: [[extract2:%[^ ]+]] = extractelement <4 x i32> %vector, i32 2
; CHECK: [[add1:%[^ ]+]] = add i32 [[add0]], [[extract2]]
; CHECK: [[extract3:%[^ ]+]] = extractelement <4 x i32> %vector, i32 3
; CHECK: [[add2:%[^ ]+]] = add i32 [[add1]], [[extract3]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(<4 x i32> %vector) {
entry:
  %res = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %vector)
  ret void
}

declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>)
