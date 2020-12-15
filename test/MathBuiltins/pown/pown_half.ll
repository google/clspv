; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define half @pown_half(half %x, i32 %y) {
entry:
  %call = call spir_func half @_Z4pownDhi(half %x, i32 %y)
  ret half %call
}

declare spir_func half @_Z4pownDhi(half, i32)

; CHECK: [[conv:%[a-zA-Z0-9_.]+]] = sitofp i32 %y to half
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call half @llvm.pow.f16(half %x, half [[conv]])
; CHECK: ret half [[call]]

