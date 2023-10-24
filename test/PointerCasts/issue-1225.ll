; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[gep:%[^ ]+]] = getelementptr { %struct.s, %struct.s }, ptr %alloca, i32 0, i32 0, i32 0, i32 1
; CHECK: load i64, ptr [[gep]], align 8

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%struct.s = type { [8 x i64], i32 }

define spir_kernel void @foo() {
entry:
  %alloca = alloca { %struct.s, %struct.s }, align 8
  %gep = getelementptr inbounds [8 x i64], ptr %alloca, i64 0, i64 1
  %load = load i64, ptr %gep, align 8
  ret void
}
