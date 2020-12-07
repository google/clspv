; RUN: clspv-opt %s -o %t.ll -ReplaceOpenCLBuiltin -ReplaceLLVMIntrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i64 @ulong_ctz(i64 %in) {
entry:
  %call = call spir_func i64 @_Z3ctzm(i64 %in)
  ret i64 %call
}

declare spir_func i64 @_Z3ctzm(i64)

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 %in, 32
; CHECK: [[hi:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i32
; CHECK: [[lo:%[a-zA-Z0-9_.]+]] = trunc i64 %in to i32
; CHECK: [[hi_ctz:%[a-zA-Z0-9_.]+]] = call i32 @llvm.cttz.i32(i32 [[hi]], i1 false)
; CHECK: [[lo_ctz:%[a-zA-Z0-9_.]+]] = call i32 @llvm.cttz.i32(i32 [[lo]], i1 false)
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[lo_ctz]], 32
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[hi_ctz]], 32
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]], i32 [[add]], i32 [[lo_ctz]]
; CHECK: zext i32 [[sel]] to i64
