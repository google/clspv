; RUN: clspv-opt %s -o %t.ll --passes=wrap-kernel
; RUN: FileCheck %s < %t.ll
; RUN: spirv-val %t.spv


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @add() {
entry:
  ret void
}

define dso_local spir_kernel void @main_kernel() {
entry:
  call spir_kernel void @add() #5
  ret void
}

; CHECK:  define dso_local spir_func void @add.inner
; CHECK-NEXT: entry:
; CHECK-NEXT: ret void

; CHECK:  define dso_local spir_kernel void @add
; CHECK-NEXT: entry:
; CHECK-NEXT: call spir_func void @add.inner
; CHECK: ret void

; CHECK:  define dso_local spir_kernel void @main_kernel
; CHECK-NEXT: entry:
; CHECK-NEXT: call spir_func void @add.inner
; CHECK ret void