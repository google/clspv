; RUN: clspv-opt %s -o %t.ll -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i8 @uchar_ctz(i8 %in) {
entry:
  %call = call spir_func i8 @_Z3ctzh(i8 %in)
  ret i8 %call
}

declare spir_func i8 @_Z3ctzh(i8)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i8 %in to i32
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call i32 @_Z3ctzj(i32 [[zext]])
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[call]], 32
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]], i32 8, i32 [[call]]
; CHECK: trunc i32 [[sel]] to  i8
