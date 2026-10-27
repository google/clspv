; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; %a and %b are merged into a single alloca, so that the select of pointers to
; either of them can be lowered into a select of indices.

; CHECK: [[alloca:%[^ ]+]] = alloca [2 x i32], align 4
; CHECK: [[select:%[^ ]+]] = select i1 %c, i32 0, i32 1
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 [[select]]
; CHECK: [[ld:%[^ ]+]] = load i32, ptr [[gep]], align 4
; CHECK: store i32 [[ld]], ptr addrspace(1) %out, align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define void @test(ptr addrspace(1) %out, i1 %c) {
entry:
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  store i32 1, ptr %a, align 4
  store i32 2, ptr %b, align 4
  %ptr = select i1 %c, ptr %a, ptr %b
  %ld = load i32, ptr %ptr, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}
