; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define <2 x double> @sincos_double2(<2 x double> %x, <2 x double>* %y) {
entry:
  %call = call spir_func <2 x double> @_Z6sincosDv2_dPU3AS0Dv2_d(<2 x double> %x, <2 x double>* %y)
  ret <2 x double> %call
}

declare spir_func <2 x double> @_Z6sincosDv2_dPU3AS0Dv2_d(<2 x double>, <2 x double>*)

; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call <2 x double> @llvm.sin.v2f64(<2 x double> %x)
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call <2 x double> @llvm.cos.v2f64(<2 x double> %x)
; CHECK: store <2 x double> [[cos]], <2 x double>* %y, align 16
; CHECK: ret <2 x double> [[sin]]

