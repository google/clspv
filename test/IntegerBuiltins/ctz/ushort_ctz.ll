; RUN: clspv-opt %s -o %t.ll --passes=replace-opencl-builtin,replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i16 @ushort_ctz(i16 %in) {
entry:
  %call = call spir_func i16 @_Z3ctzt(i16 %in)
  ret i16 %call
}

declare spir_func i16 @_Z3ctzt(i16)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext i16 %in to i32
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i32 [[zext]], 65536
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call i32 @llvm.cttz.i32(i32 [[or]], i1 false)
; CHECK: trunc i32 [[call]] to i16


