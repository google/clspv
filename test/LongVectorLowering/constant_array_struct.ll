; RUN: clspv-opt --passes=long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll
;
; This test covers ConstantArray and ConstantStruct containing long vectors,
; including opaque-pointer users such as @llvm.memcpy.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-NOT: <8 x

%struct.S = type { <8 x i32>, <8 x float> }

@const_arr = addrspace(2) constant [2 x <8 x i32>] [
  <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>,
  <8 x i32> <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
], align 32

@const_struct = addrspace(2) constant %struct.S {
  <8 x i32> <i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8>,
  <8 x float> <float 1.0, float 2.0, float 3.0, float 4.0, float 5.0, float 6.0, float 7.0, float 8.0>
}, align 32

@memcpy_arr = private unnamed_addr addrspace(2) constant [2 x <8 x i32>] [
  <8 x i32> <i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17>,
  <8 x i32> zeroinitializer
], align 32

declare void @llvm.memcpy.p0.p2.i32(ptr noalias nocapture writeonly, ptr addrspace(2) noalias nocapture readonly, i32, i1 immarg)

define spir_func [2 x <8 x i32>] @test_array() {
  %v = load [2 x <8 x i32>], ptr addrspace(2) @const_arr, align 32
  ret [2 x <8 x i32>] %v
}

define spir_func %struct.S @test_struct() {
  %v = load %struct.S, ptr addrspace(2) @const_struct, align 32
  ret %struct.S %v
}

define spir_func <8 x i32> @test_memcpy(i32 %i) {
  %local = alloca [2 x <8 x i32>], align 32
  call void @llvm.memcpy.p0.p2.i32(ptr align 32 %local, ptr addrspace(2) align 32 @memcpy_arr, i32 64, i1 false)
  %gep = getelementptr inbounds [2 x <8 x i32>], ptr %local, i32 0, i32 %i
  %v = load <8 x i32>, ptr %gep, align 32
  ret <8 x i32> %v
}

; CHECK-DAG: @const_arr = addrspace(2) constant [2 x [8 x i32]] {{\[\[}}8 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7], [8 x i32] [i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15]], align 32
; CHECK-DAG: @const_struct = addrspace(2) constant { [8 x i32], [8 x float] } { [8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], [8 x float] [float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00, float 5.000000e+00, float 6.000000e+00, float 7.000000e+00, float 8.000000e+00] }, align 32
; CHECK-DAG: @memcpy_arr = private unnamed_addr addrspace(2) constant [2 x [8 x i32]] {{\[\[}}8 x i32] [i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17], [8 x i32] zeroinitializer], align 32
; CHECK-NOT: <8 x
; CHECK-LABEL: define spir_func [8 x i32] @test_memcpy(i32 %i)
; CHECK: %[[LOCAL:[a-zA-Z0-9_.]+]] = alloca [2 x [8 x i32]], align 32
; CHECK: call void @llvm.memcpy.p0.p2.i32(ptr align 32 %[[LOCAL]], ptr addrspace(2) align 32 @memcpy_arr, i32 64, i1 false)
; CHECK-LABEL: define spir_func { [8 x i32], [8 x float] } @test_struct()
; CHECK-LABEL: define spir_func [2 x [8 x i32]] @test_array()
