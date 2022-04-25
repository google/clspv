; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define float @pown_float(float %x, i32 %y) {
entry:
  %call = call spir_func float @_Z4pownfi(float %x, i32 %y)
  ret float %call
}

declare spir_func float @_Z4pownfi(float, i32)

; CHECK: [[conv:%[a-zA-Z0-9_.]+]] = sitofp i32 %y to float
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call float @llvm.pow.f32(float %x, float [[conv]])
; CHECK: ret float [[call]]
