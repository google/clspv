; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @islessgreater_float(float %x, float %y) {
entry:
  %call = call spir_func i32 @_Z13islessgreaterff(float %x, float %y)
  ret i32 %call
}

declare spir_func i32 @_Z13islessgreaterff(float, float)

; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = fcmp one float %x, %y
; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i1 [[cmp]] to i32
; CHECK: ret i32 [[zext]]
