; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i64> @long_clz(<2 x i64> %in) {
entry:
  %call = call spir_func <2 x i64> @_Z3clzl(<2 x i64> %in)
  ret <2 x i64> %call
}

declare <2 x i64> @_Z3clzl(<2 x i64>)

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr <2 x i64> %in, splat (i64 32)
; CHECK: [[top:%[a-zA-Z0-9_.]+]] = trunc <2 x i64> [[shr]] to <2 x i32>
; CHECK: [[bot:%[a-zA-Z0-9_.]+]] = trunc <2 x i64> %in to <2 x i32>
; CHECK: [[top_clz:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.ctlz.v2i32(<2 x i32> [[top]], i1 false)
; CHECK: [[bot_clz:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.ctlz.v2i32(<2 x i32> [[bot]], i1 false)
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq <2 x i32> [[top_clz]], splat (i32 32)
; CHECK: [[bot_adjust:%[a-zA-Z0-9_.]+]] = add <2 x i32> [[bot_clz]], splat (i32 32)
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[cmp]], <2 x i32> [[bot_adjust]], <2 x i32> [[top_clz]]
; CHECK: [[zext:%[a-zA-Z0-9_.]+]] = zext <2 x i32> [[sel]] to <2 x i64>
; CHECK: ret <2 x i64> [[zext]]
; CHECK: declare <2 x i32> @llvm.ctlz.v2i32(<2 x i32>, i1 immarg)

