; RUN: clspv-opt %s -o %t.ll --untyped-pointers --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: call void @llvm.memcpy.p1.p1.i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.outer = type { [2 x %struct.inner] }
%struct.inner = type { <4 x i32>, <4 x i64> }

define dso_local spir_kernel void @fct1(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 64, i1 false)
  ret void
}

declare void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noalias nocapture writeonly %0, ptr addrspace(1) noalias nocapture readonly %1, i32 %2, i1 immarg %3)
