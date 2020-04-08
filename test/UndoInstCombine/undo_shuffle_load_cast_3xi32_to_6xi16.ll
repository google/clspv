; RUN: clspv-opt %s -o %t.ll -UndoInstCombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <3 x i32>, <3 x i32>* %alloca
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[ld]], i32 1
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex0]] to i16
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i16> zeroinitializer, i16 [[trunc0]], i32 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[ld]], i32 2
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i32 [[ex1]] to i16
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i16> [[in0]], i16 [[trunc1]], i32 1
; CHECK: store <2 x i16> [[in1]]

define void @test(<2 x i16> addrspace(1)* %out) {
entry:
  %alloca = alloca <3 x i32>
  %cast = bitcast <3 x i32>* %alloca to <6 x i16>*
  %load = load <6 x i16>, <6 x i16>* %cast, align 16
  %conv = shufflevector <6 x i16> %load, <6 x i16> undef, <2 x i32> <i32 2, i32 4>
  store <2 x i16> %conv, <2 x i16> addrspace(1)* %out, align 1
  ret void
}

