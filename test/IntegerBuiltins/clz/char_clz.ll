; RUN: clspv-opt -ReplaceOpenCLBuiltin -ReplaceLLVMIntrinsics %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i8 @char_clz(i8 %in) {
entry:
  %call = call spir_func i8 @_Z3clzc(i8 %in)
  ret i8 %call
}

declare spir_func i8 @_Z3clzc(i8)
declare spir_func i32 @_Z3clzj(i32)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i8 %in to i32
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call i32 @llvm.ctlz.i32(i32 [[zext]], i1 false)
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub i32 [[call]], 24
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[sub]] to i8
; CHECK: ret i8 [[trunc]]
; CHECK: declare i32 @llvm.ctlz.i32(i32, i1 immarg)

