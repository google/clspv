; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x half> @fdim_half2(<2 x half> %x, <2 x half> %y) {
entry:
  %call = call spir_func <2 x half> @_Z4fdimDv2_fS_(<2 x half> %x, <2 x half> %y)
  ret <2 x half> %call
}

declare spir_func <2 x half> @_Z4fdimDv2_fS_(<2 x half>, <2 x half>)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub <2 x half> %x, %y
; CHECK: [[gt:%[a-zA-Z0-9_.]+]] = fcmp ugt <2 x half> %x, %y
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[gt]], <2 x half> [[sub]], <2 x half> zeroinitializer
; CHECK: ret <2 x half> [[sel]]

