; RUN: clspv-opt %s -o %t.ll -UndoInstCombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(<4 x i32> %in, <4 x i8> addrspace(1)* %out) {
entry:
  ; CHECK-NOT: bitcast
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <4 x i32> %in, i32 0
  ; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex0]] to i8
  ; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> zeroinitializer, i8 [[trunc0]], i32 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <4 x i32> %in, i32 1
  ; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex1]] to i8
  ; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert0]], i8 [[trunc1]], i32 1
  ; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractelement <4 x i32> %in, i32 2
  ; CHECK: [[trunc2:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex2]] to i8
  ; CHECK: [[insert2:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert1]], i8 [[trunc2]], i32 2
  ; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractelement <4 x i32> %in, i32 3
  ; CHECK: [[trunc3:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex3]] to i8
  ; CHECK: [[insert3:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert2]], i8 [[trunc3]], i32 3
  ; CHECK: store <4 x i8> [[insert3]]
  %cast = bitcast <4 x i32> %in to <16 x i8>
  %conv = shufflevector <16 x i8> %cast, <16 x i8> undef, <4 x i32> <i32 0, i32 4, i32 8, i32 12>
  store <4 x i8> %conv, <4 x i8> addrspace(1)* %out, align 1
  ret void
}


