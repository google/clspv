; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i32> @float2_isunordered(<2 x float> %x, <2 x float> %y) {
entry:
  %call = call spir_func <2 x i32> @_Z11isunorderedDv2_fS_(<2 x float> %x, <2 x float> %y)
  ret <2 x i32> %call
}

declare spir_func <2 x i32> @_Z11isunorderedDv2_fS_(<2 x float>, <2 x float>)

; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = fcmp uno <2 x float> %x, %y
; CHECK: [[sext:%[a-zA-Z0-9_.]+]] = sext <2 x i1> [[cmp]] to <2 x i32>
; CHECK: ret <2 x i32> [[sext]]

