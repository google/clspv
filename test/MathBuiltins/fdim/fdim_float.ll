; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define float @fdim_float(float %x, float %y) {
entry:
  %call = call spir_func float @_Z4fdimff(float %x, float %y)
  ret float %call
}

declare spir_func float @_Z4fdimff(float, float)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub float %x, %y
; CHECK: [[gt:%[a-zA-Z0-9_.]+]] = fcmp ugt float %x, %y
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[gt]], float [[sub]], float 0.000000e+00
; CHECK: ret float [[sel]]
