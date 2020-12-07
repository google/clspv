; RUN: clspv-opt %s -o %t.ll -ReplaceOpenCLBuiltin -ReplaceLLVMIntrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i64> @ulong_ctz(<2 x i64> %in) {
entry:
  %call = call spir_func <2 x i64> @_Z3ctzDv2_m(<2 x i64> %in)
  ret <2 x i64> %call
}

declare spir_func <2 x i64> @_Z3ctzDv2_m(<2 x i64>)

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr <2 x i64> %in, <i64 32, i64 32>
; CHECK: [[hi:%[a-zA-Z0-9_.]+]] = trunc <2 x i64> [[shr]] to <2 x i32>
; CHECK: [[lo:%[a-zA-Z0-9_.]+]] = trunc <2 x i64> %in to <2 x i32>
; CHECK: [[hi_ctz:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.cttz.v2i32(<2 x i32> [[hi]], i1 false)
; CHECK: [[lo_ctz:%[a-zA-Z0-9_.]+]] = call <2 x i32> @llvm.cttz.v2i32(<2 x i32> [[lo]], i1 false)
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq <2 x i32> [[lo_ctz]], <i32 32, i32 32>
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add <2 x i32> [[hi_ctz]], <i32 32, i32 32>
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[cmp]], <2 x i32> [[add]], <2 x i32> [[lo_ctz]]
; CHECK: zext <2 x i32> [[sel]] to <2 x i64>

