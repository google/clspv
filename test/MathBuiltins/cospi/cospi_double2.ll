; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x double> @cospi_double2(<2 x double> %x) {
entry:
  %call = call spir_func <2 x double> @_Z5cospiDv2_d(<2 x double> %x)
  ret <2 x double> %call
}

declare spir_func <2 x double> @_Z5cospiDv2_d(<2 x double>)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = fmul <2 x double> %x, <double  0x400921FB54442D18, double  0x400921FB54442D18>
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call <2 x double> @llvm.cos.v2f64(<2 x double> [[mul]])

