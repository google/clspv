; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define <2 x double> @pown_double2(<2 x double> %x, <2 x i32> %y) {
entry:
  %call = call spir_func <2 x double> @_Z4pownDv2dDv2_i(<2 x double> %x, <2 x i32> %y)
  ret <2 x double> %call
}

declare spir_func <2 x double> @_Z4pownDv2dDv2_i(<2 x double>, <2 x i32>)

; CHECK: [[conv:%[a-zA-Z0-9_.]+]] = sitofp <2 x i32> %y to <2 x double>
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call <2 x double> @llvm.pow.v2f64(<2 x double> %x, <2 x double> [[conv]])
; CHECK: ret <2 x double> [[call]]


