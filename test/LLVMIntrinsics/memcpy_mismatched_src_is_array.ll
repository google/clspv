; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @src_array(float addrspace(1)* %A, i32 %n, i32 %k) {
entry:
  %src = alloca [7 x float]
  store [7 x float] [float 0.0, float 1.0, float 2.0, float 3.0, float 4.0, float 5.0, float 6.0], [7 x float]* %src
  call void @llvm.memcpy.p1i8.p0i8.i64(i8 addrspace(1)* align 4 %A, i8* align 4 %src, i64 28, i1 false)
  ret void
}

declare void @llvm.memcpy.p1i8.p0i8.i64(i8 addrspace(1)*, i8*, i64, i1)

; CHECK-NOT: bitcast
; CHECK: [[src_gep:%[a-zA-Z0-9_.]+]] = getelementptr inbounds [7 x float], ptr %src
; CHECK: [[load:%[a-zA-Z0-9_.]+]] = load [7 x float], ptr [[src_gep]]
; CHECK: [[dst_gep:%[a-zA-Z0-9_.]+]] = getelementptr [7 x float], ptr addrspace(1)
; CHECK: store [7 x float] [[load]], ptr addrspace(1) [[dst_gep]]
