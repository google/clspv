; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK-COUNT-10:  store [2 x i8] zeroinitializer, ptr addrspace(1)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) %source)  {
entry:
  %0 = load [2 x i8], ptr addrspace(1) %source, align 2
  store [5 x i32] zeroinitializer, ptr addrspace(1) %source, align 4
  ret void
}
