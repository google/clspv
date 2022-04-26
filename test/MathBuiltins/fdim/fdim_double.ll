; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define double @fdim_double(double %x, double %y) {
entry:
  %call = call spir_func double @_Z4fdimdd(double %x, double %y)
  ret double %call
}

declare spir_func double @_Z4fdimdd(double, double)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub double %x, %y
; CHECK: [[gt:%[a-zA-Z0-9_.]+]] = fcmp ugt double %x, %y
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[gt]], double [[sub]], double 0.000000e+00
; CHECK: ret double [[sel]]

