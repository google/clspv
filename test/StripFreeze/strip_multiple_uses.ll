; RUN: clspv-opt %s -o %t.ll -StripFreeze
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: freeze float
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> zeroinitializer, float %in, i32 0
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> [[in0]], float %in, i32 1
; CHECK: ret <2 x float> [[in1]]
define <2 x float> @foo(float %in) {
entry:
  %freeze1 = freeze float %in
  %freeze2 = freeze float %in
  %in0 = insertelement <2 x float> zeroinitializer, float %freeze1, i32 0
  %in1 = insertelement <2 x float> %in0, float %freeze2, i32 1
  ret <2 x float> %in1
}

