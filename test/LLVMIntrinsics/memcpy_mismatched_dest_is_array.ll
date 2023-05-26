; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @src_array(ptr addrspace(1) %A, i32 %n, i32 %k) {
entry:
  %dst = alloca [7 x float], align 4
  call void @llvm.memcpy.p0i8.p1i8.i64(i8* align 4 %dst, ptr addrspace(1) align 4 %A, i64 28, i1 false)
  ret void
}

declare void @llvm.memcpy.p0i8.p1i8.i64(i8*, ptr addrspace(1), i64, i1)

; CHECK-NOT: bitcast
; CHECK: [[src_gep:%[a-zA-Z0-9_.]+]] = getelementptr inbounds [7 x float], ptr addrspace(1)
; CHECK: [[load:%[a-zA-Z0-9_.]+]] = load [7 x float], ptr addrspace(1) [[src_gep]]
; CHECK: [[dst_gep:%[a-zA-Z0-9_.]+]] = getelementptr [7 x float], ptr %dst,
; CHECK: store [7 x float] [[load]], ptr [[dst_gep]]
