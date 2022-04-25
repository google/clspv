; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @src_array(float addrspace(1)* %A, i32 %n, i32 %k) {
entry:
  %src = alloca [7 x float]
  store [7 x float] [float 0.0, float 1.0, float 2.0, float 3.0, float 4.0, float 5.0, float 6.0], [7 x float]* %src
  %dst_cast = bitcast float addrspace(1)* %A to i8 addrspace(1)*
  %src_cast = bitcast [7 x float]* %src to i8*
  call void @llvm.memcpy.p1i8.p0i8.i64(i8 addrspace(1)* align 4 %dst_cast, i8* align 4 %src_cast, i64 28, i1 false)
  ret void
}

declare void @llvm.memcpy.p1i8.p0i8.i64(i8 addrspace(1)*, i8*, i64, i1)

; CHECK-NOT: bitcast
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 0
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 0
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 1
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 1
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 2
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 2
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 3
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 3
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 4
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 4
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 5
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 5
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
; CHECK: [[src_gep:%[0-9a-zA-Z_.]+]] = getelementptr inbounds [7 x float], [7 x float]* %src, i32 0, i32 6
; CHECK: [[dst_gep:%[0-9a-zA-Z_.]+]] = getelementptr float, float addrspace(1)* %A, i32 6
; CHECK: call void @_Z17spirv.copy_memory(float addrspace(1)* [[dst_gep]], float* [[src_gep]], i32 4, i32 0)
