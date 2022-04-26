; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(<4 x i32> %in, i8 addrspace(1)* %out) {
entry:
  ; CHECK-NOT: bitcast
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i32> %in, i32 0
  ; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex]] to i8
  ; CHECK: store i8 [[trunc]]
  %cast = bitcast <4 x i32> %in to <16 x i8>
  %conv = extractelement <16 x i8> %cast, i32 0
  store i8 %conv, i8 addrspace(1)* %out, align 1
  ret void
}

