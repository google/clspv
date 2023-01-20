; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @many_null_bytes(ptr addrspace(1) %data) {
entry:
  call void @llvm.memset.p1i8.i32(ptr addrspace(1) %data, i8 0, i32 16, i1 false)
  ret void
}

declare void @llvm.memset.p1i8.i32(ptr addrspace(1), i8, i32, i1)

; CHECK-NOT: bitcast
; CHECK: store <4 x i32> zeroinitializer, ptr addrspace(1)
