; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i64> @islessgreater_double2(<2 x double> %x, <2 x double> %y) {
entry:
  %call = call spir_func <2 x i64> @_Z13islessgreaterDv2_dS_(<2 x double> %x, <2 x double> %y)
  ret <2 x i64> %call
}

declare spir_func <2 x i64> @_Z13islessgreaterDv2_dS_(<2 x double>, <2 x double>)

; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = fcmp one <2 x double> %x, %y
; CHECK: [[sext:%[a-zA-Z0-9_.]+]] = sext <2 x i1> [[cmp]] to <2 x i64>
; CHECK: ret <2 x i64> [[sext]]

