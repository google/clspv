; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define half @fdim_half(half %x, half %y) {
entry:
  %call = call spir_func half @_Z4fdimDhDh(half %x, half %y)
  ret half %call
}

declare spir_func half @_Z4fdimDhDh(half, half)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub half %x, %y
; CHECK: [[gt:%[a-zA-Z0-9_.]+]] = fcmp ugt half %x, %y
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[gt]], half [[sub]], half 0xH0000
; CHECK: ret half [[sel]]

