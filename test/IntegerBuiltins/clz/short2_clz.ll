; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i16> @short_clz(<2 x i16> %in) {
entry:
  %call = call spir_func <2 x i16> @_Z3clzs(<2 x i16> %in)
  ret <2 x i16> %call
}

declare spir_func <2 x i16> @_Z3clzs(<2 x i16>)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext <2 x i16> %in to <2 x i32>
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call <2 x i32> @_Z3clzDv2_j(<2 x i32> [[zext]])
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub <2 x i32> [[call]], <i32 16, i32 16>
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc <2 x i32> [[sub]] to <2 x i16>
; CHECK: ret <2 x i16> [[trunc]]
; CHECK: declare <2 x i32> @_Z3clzDv2_j(<2 x i32>)

