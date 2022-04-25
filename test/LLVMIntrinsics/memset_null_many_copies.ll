; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @many_null_bytes(float addrspace(1)* %data) {
entry:
  %cast = bitcast float addrspace(1)* %data to i8 addrspace(1)*
  call void @llvm.memset.p1i8.i32(i8 addrspace(1)* %cast, i8 0, i32 16, i1 false)
  ret void
}

declare void @llvm.memset.p1i8.i32(i8 addrspace(1)*, i8, i32, i1)

; CHECK-NOT: bitcast
; CHECK: store float 0.000000e+00, float addrspace(1)* %data
; CHECK: [[gep0:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %data, i32 1
; CHECK: store float 0.000000e+00, float addrspace(1)* [[gep0]]
; CHECK: [[gep1:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* [[gep0]], i32 1
; CHECK: store float 0.000000e+00, float addrspace(1)* [[gep1]]
; CHECK: [[gep2:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* [[gep1]], i32 1
; CHECK: store float 0.000000e+00, float addrspace(1)* [[gep2]]
