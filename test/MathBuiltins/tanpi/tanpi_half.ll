; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define half @tanpi_half(half %x) {
entry:
  %call = call spir_func half @_Z5tanpiDh(half %x)
  ret half %call
}

declare spir_func half @_Z5tanpiDh(half)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = fmul half %x, 0xH4248
; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call half @llvm.sin.f16(half [[mul]])
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call half @llvm.cos.f16(half [[mul]])
; CHECK: [[div:%[a-zA-Z0-9_.]+]] = fdiv half [[sin]], [[cos]]

