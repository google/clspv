; RUN: clspv-opt %s -o %t.ll --passes=replace-opencl-builtin,replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i8> @uchar_ctz(<2 x i8> %in) {
entry:
  %call = call spir_func <2 x i8> @_Z3ctzDv2_h(<2 x i8> %in)
  ret <2 x i8> %call
}

declare spir_func <2 x i8> @_Z3ctzDv2_h(<2 x i8>)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext <2 x i8> %in to <2 x i32>
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or <2 x i32> [[zext]], splat (i32 256)
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.cttz.v2i32(<2 x i32> [[or]], i1 false)
; CHECK: trunc <2 x i32> [[call]] to <2 x i8>
