; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define <2 x double> @expm1_double2(<2 x double> %x) {
entry:
  %call = call spir_func <2 x double> @_Z5expm1Dv2_d(<2 x double> %x)
  ret <2 x double> %call
}

declare spir_func <2 x double> @_Z5expm1Dv2_d(<2 x double> %x)

; CHECK: [[exp:%[a-zA-Z0-9_.]+]] = call <2 x double> @llvm.exp.v2f64(<2 x double> %x)
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub <2 x double> [[exp]], <double 1.000000e+00, double 1.000000e+00>
; CHECK: ret <2 x double> [[sub]]


