; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define half @expm1_half(half %x) {
entry:
  %call = call spir_func half @_Z5expm1Dh(half %x)
  ret half %call
}

declare spir_func half @_Z5expm1Dh(half %x)

; CHECK: [[exp:%[a-zA-Z0-9_.]+]] = call half @llvm.exp.f16(half %x)
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub half [[exp]], 0xH3C00
; CHECK: ret half [[sub]]

