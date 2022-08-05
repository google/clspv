; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @call_assume_kernel(i16 %in, i1 addrspace(1)* %out) {
entry:
  %x = add i16 %in, 0
  %cmp.i = icmp slt i16 %x, 10
  tail call void @llvm.assume(i1 %cmp.i)
  store i1 %cmp.i, i1 addrspace(1)* %out
  ret void
}

declare void @llvm.assume(i1 noundef)

; CHECK-NOT: llvm.assume
