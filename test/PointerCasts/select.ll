; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[select:%[^ ]+]] = select
; CHECK: getelementptr [8 x i8], ptr [[select]], i32 0, i64 3

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @foo(ptr %a, ptr %b, i1 %cmp) {
entry:
  %0 = getelementptr [8 x i8], ptr %a, i64 1
  %1 = getelementptr [8 x i8], ptr %b, i64 2
  %2 = select i1 %cmp, ptr %0, ptr %1
  %3 = getelementptr i8, ptr %2, i64 3
  ret void
}
