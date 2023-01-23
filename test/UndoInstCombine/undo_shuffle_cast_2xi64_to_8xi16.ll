; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(<2 x i64> %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-NOT: bitcast
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i64> %in, i32 1
  ; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i64 [[ex0]] to i16
  ; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i16> zeroinitializer, i16 [[trunc0]], i32 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i64> %in, i32 2
  ; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i64 [[ex1]] to i16
  ; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i16> [[insert0]], i16 [[trunc1]], i32 1
  ; CHECK: store <2 x i16> [[insert1]]
  %cast = bitcast <2 x i64> %in to <8 x i16>
  %conv = shufflevector <8 x i16> %cast, <8 x i16> undef, <2 x i32> <i32 4, i32 8>
  store <2 x i16> %conv, ptr addrspace(1) %out, align 1
  ret void
}

