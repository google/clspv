; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @isnormal_float(float %x) {
entry:
  %call = call spir_func i32 @_Z8isnormalf(float %x)
  ret i32 %call
}

declare spir_func i32 @_Z8isnormalf(float)

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float %x to i32
; CHECK: [[abs:%[a-zA-Z0-9_.]+]] = and i32 [[cast]], 2147483647
; CHECK: [[lt:%[a-zA-Z0-9_.]+]] = icmp ult i32 [[abs]], 2139095040
; CHECK: [[ge:%[a-zA-Z0-9_.]+]] = icmp uge i32 [[abs]], 8388608
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i1 [[lt]], [[ge]]
; CHECK: [[zext:%[a-zA-Z0-9_]+]] = zext i1 [[and]] to i32
; CHECK: ret i32 [[zext]]
