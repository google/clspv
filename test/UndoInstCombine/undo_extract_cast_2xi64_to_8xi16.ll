; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(<2 x i64> %in, i16 addrspace(1)* %out) {
entry:
  ; CHECK-NOT: bitcast
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i64> %in, i32 0
  ; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[ex]] to i16
  ; CHECK: store i16 [[trunc]]
  %cast = bitcast <2 x i64> %in to <8 x i16>
  %conv = extractelement <8 x i16> %cast, i32 0
  store i16 %conv, i16 addrspace(1)* %out, align 2
  ret void
}


