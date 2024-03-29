; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <3 x i32>, ptr %alloca
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[ld]], i32 0
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex]] to i16
; CHECK: sext i16 [[trunc]] to i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) nocapture %out) {
entry:
  %alloca = alloca <3 x i32>
  %0 = load <6 x i16>, ptr %alloca
  %conv = extractelement <6 x i16> %0, i32 0
  %conv1 = sext i16 %conv to i32
  store i32 %conv1, i32 addrspace(1)* %out, align 4
  ret void
}


