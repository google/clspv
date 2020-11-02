; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i64 @long_clz(i64 %in) {
entry:
  %call = call spir_func i64 @_Z3clzl(i64 %in)
  ret i64 %call
}

declare i64 @_Z3clzl(i64)

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 %in, 32
; CHECK: [[top:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i32
; CHECK: [[bot:%[a-zA-Z0-9_.]+]] = trunc i64 %in to i32
; CHECK: [[top_clz:%[a-zA-Z0-9_.]+]] = call i32 @_Z3clzj(i32 [[top]])
; CHECK: [[bot_clz:%[a-zA-Z0-9_.]+]] = call i32 @_Z3clzj(i32 [[bot]])
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[top_clz]], 32
; CHECK: [[bot_adjust:%[a-zA-Z0-9_.]+]] = add i32 [[bot_clz]], 32
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]], i32 [[bot_adjust]], i32 [[top_clz]]
; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i32 [[sel]] to i64
; CHECK: ret i64 [[zext]]
; CHECK: declare i32 @_Z3clzj(i32)
