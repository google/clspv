; RUN: clspv-opt %s --passes=spirv-producer -producer-out-file %t.spv -o %t.ll 2>&1 | FileCheck %s --check-prefix=WARN
; RUN: spirv-dis -o %t.spvasm %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; WARN: warning: loop has no exit block

; CHECK: OpLoopMerge [[merge:%[a-zA-Z0-9_]+]] {{%[a-zA-Z0-9_]+}} None
; CHECK: [[merge]] = OpLabel
; CHECK-NEXT: OpUnreachable

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @kernel() {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.cond, %entry
  br label %for.cond
}
