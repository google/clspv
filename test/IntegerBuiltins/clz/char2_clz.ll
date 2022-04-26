; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i8> @char_clz(<2 x i8> %in) {
entry:
  %call = call spir_func <2 x i8> @_Z3clzc(<2 x i8> %in)
  ret <2 x i8> %call
}

declare spir_func <2 x i8> @_Z3clzc(<2 x i8>)
declare spir_func <2 x i32> @_Z3clzDv2_j(<2 x i32>)

; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext <2 x i8> %in to <2 x i32>
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.ctlz.v2i32(<2 x i32> [[zext]], i1 false)
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub <2 x i32> [[call]], <i32 24, i32 24>
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc <2 x i32> [[sub]] to <2 x i8>
; CHECK: ret <2 x i8> [[trunc]]
; CHECK: declare <2 x i32> @llvm.ctlz.v2i32(<2 x i32>, i1 immarg)

