; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.TestStruct = type { i32, i64 }

declare void @llvm.memset.p1.i32(ptr addrspace(1), i8, i32, i1)

; ------------------------------------------------------------------------------
; 1. Integer (T->isIntegerTy())
; ------------------------------------------------------------------------------
define dso_local spir_kernel void @test_integer(ptr addrspace(1) %dst) {
entry:
  ; Hint to clspv::InferType that %dst is an i32 pointer
  %0 = getelementptr i32, ptr addrspace(1) %dst, i32 0
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 42, i32 4, i1 false)
  ret void
}

; CHECK-LABEL: @test_integer
; CHECK: getelementptr i32, ptr addrspace(1) %dst, i32 0
; CHECK: [[gep_int:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dst, i32 0
; CHECK: store i32 707406378, ptr addrspace(1) [[gep_int]]


; ------------------------------------------------------------------------------
; 2. Floating Point (T->isFloatingPointTy())
; ------------------------------------------------------------------------------
define dso_local spir_kernel void @test_float(ptr addrspace(1) %dst) {
entry:
  ; Hint to clspv::InferType that %dst is a float pointer
  %0 = getelementptr float, ptr addrspace(1) %dst, i32 0
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 42, i32 4, i1 false)
  ret void
}

; CHECK-LABEL: @test_float
; CHECK: getelementptr float, ptr addrspace(1) %dst, i32 0
; CHECK: [[gep_flt:%[^ ]+]] = getelementptr float, ptr addrspace(1) %dst, i32 0
; CHECK: store float f0x2A2A2A2A, ptr addrspace(1) [[gep_flt]]


; ------------------------------------------------------------------------------
; 3. Fixed Vector (dyn_cast<FixedVectorType>(T))
; ------------------------------------------------------------------------------
define dso_local spir_kernel void @test_vector(ptr addrspace(1) %dst) {
entry:
  ; Hint to clspv::InferType that %dst is a <4 x i32> pointer
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %dst, i32 0
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 42, i32 16, i1 false)
  ret void
}

; CHECK-LABEL: @test_vector
; CHECK: getelementptr <4 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK: [[gep_vec:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK: store <4 x i32> splat (i32 707406378), ptr addrspace(1) [[gep_vec]]


; ------------------------------------------------------------------------------
; 4. Array (dyn_cast<ArrayType>(T))
; ------------------------------------------------------------------------------
define dso_local spir_kernel void @test_array(ptr addrspace(1) %dst) {
entry:
  ; Hint to clspv::InferType that %dst is a [2 x i32] pointer
  %0 = getelementptr [2 x i32], ptr addrspace(1) %dst, i32 0
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 42, i32 8, i1 false)
  ret void
}

; CHECK-LABEL: @test_array
; CHECK: getelementptr [2 x i32], ptr addrspace(1) %dst, i32 0
; CHECK: [[gep_arr:%[^ ]+]] = getelementptr [2 x i32], ptr addrspace(1) %dst, i32 0
; CHECK: store [2 x i32] [i32 707406378, i32 707406378], ptr addrspace(1) [[gep_arr]]


; ------------------------------------------------------------------------------
; 5. Struct (dyn_cast<StructType>(T))
; ------------------------------------------------------------------------------
define dso_local spir_kernel void @test_struct(ptr addrspace(1) %dst) {
entry:
  ; Hint to clspv::InferType that %dst is a %struct.TestStruct pointer
  %0 = getelementptr %struct.TestStruct, ptr addrspace(1) %dst, i32 0
  ; Size is 16 bytes due to standard 64-bit padding between i32 and i64
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 42, i32 16, i1 false)
  ret void
}

; CHECK-LABEL: @test_struct
; CHECK: getelementptr %struct.TestStruct, ptr addrspace(1) %dst, i32 0
; CHECK: [[gep_str:%[^ ]+]] = getelementptr %struct.TestStruct, ptr addrspace(1) %dst, i32 0
; CHECK: store %struct.TestStruct { i32 707406378, i64 3038287259199220266 }, ptr addrspace(1) [[gep_str]]
