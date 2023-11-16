; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[alloca:%[^ ]+]] = alloca [65 x i32], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr [65 x i32], ptr [[alloca]], i32 0
; CHECK:  [[load:%[^ ]+]] = load [65 x i32], ptr [[gep]], align 4
; CHECK-COUNT-65:  extractvalue [65 x i32] [[load]]
; CHECK-COUNT-65:  insertvalue [65 x i32]
; CHECK-COUNT-65:  extractvalue [65 x i32]
; CHECK-COUNT-64:  insertvalue [64 x i32]
; CHECK:  [[v:%[^ ]+]] = insertvalue %struct.pw poison, [64 x i32] {{.*}}, 0
; CHECK:  insertvalue %struct.pw [[v]], i32 {{.*}}, 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.pw = type { [64 x i32], i32 }

define spir_kernel void @foo(ptr addrspace(1) %source) {
entry:
  %alloca = alloca [65 x i32], align 4
  %gep = getelementptr inbounds %struct.pw, ptr %alloca, i32 0
  %load = load %struct.pw, ptr %gep, align 4
  ret void
}
