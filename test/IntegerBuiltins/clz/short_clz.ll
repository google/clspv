; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i16 @short_clz(i16 %in) {
entry:
  %call = call spir_func i16 @_Z3clzs(i16 %in)
  ret i16 %call
}

declare spir_func i16 @_Z3clzs(i16)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i16 %in to i32
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call i32 @_Z3clzj(i32 [[zext]])
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub i32 [[call]], 16
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[sub]] to i16
; CHECK: ret i16 [[trunc]]
; CHECK: declare i32 @_Z3clzj(i32)
