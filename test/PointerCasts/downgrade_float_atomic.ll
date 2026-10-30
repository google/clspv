; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-LABEL: define spir_kernel void @test_atomicrmw_and_float_access(
; CHECK: %[[GEP0:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 0
; CHECK: %[[GEP0_LD:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %[[GEP0]], i32 0
; CHECK: %[[LD_I32:[a-zA-Z0-9_]+]] = load i32, ptr addrspace(1) %[[GEP0_LD]], align 4
; CHECK: %[[LD_F32:[a-zA-Z0-9_]+]] = bitcast i32 %[[LD_I32]] to float
; CHECK: %[[GEP_ATOMIC:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
; CHECK: atomicrmw add ptr addrspace(1) %[[GEP_ATOMIC]], i32 1 monotonic
; CHECK: %[[ST_I32:[a-zA-Z0-9_]+]] = bitcast float %[[LD_F32]] to i32
; CHECK: %[[GEP0_ST:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %[[GEP0]], i32 0
; CHECK: store i32 %[[ST_I32]], ptr addrspace(1) %[[GEP0_ST]], align 4

define spir_kernel void @test_atomicrmw_and_float_access(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %gep0 = getelementptr float, ptr addrspace(1) %buf, i32 0
  %f = load float, ptr addrspace(1) %gep0, align 4
  %gep_atomic = getelementptr float, ptr addrspace(1) %buf, i32 %idx
  %old = atomicrmw add ptr addrspace(1) %gep_atomic, i32 1 monotonic
  store float %f, ptr addrspace(1) %gep0, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_chained_gep_and_atomic_call(
; CHECK: %[[GEP1:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
; CHECK: %[[GEP2:[a-zA-Z0-9_]+]] = getelementptr i32, ptr addrspace(1) %[[GEP1]], i32 2
; CHECK: call spir_func i32 @_Z10atomic_addPU3AS1Vii(ptr addrspace(1) %[[GEP2]], i32 5)

define spir_kernel void @test_chained_gep_and_atomic_call(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %gep1 = getelementptr float, ptr addrspace(1) %buf, i32 %idx
  %gep2 = getelementptr float, ptr addrspace(1) %gep1, i32 2
  %old = call spir_func i32 @_Z10atomic_addPU3AS1Vii(ptr addrspace(1) %gep2, i32 5)
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_non_atomic_load_not_downgraded(
; CHECK: %gep = getelementptr float, ptr addrspace(1) %buf, i32 %idx
; CHECK: %[[GEP_LD:[a-zA-Z0-9_]+]] = getelementptr float, ptr addrspace(1) %gep, i32 0
; CHECK: %[[LD_F:[a-zA-Z0-9_]+]] = load float, ptr addrspace(1) %[[GEP_LD]], align 4
; CHECK: %[[BC:[a-zA-Z0-9_]+]] = bitcast float %[[LD_F]] to i32
; CHECK: store i32 %[[BC]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_non_atomic_load_not_downgraded(ptr addrspace(1) %buf, ptr addrspace(1) %out, i32 %idx) {
entry:
  %gep = getelementptr float, ptr addrspace(1) %buf, i32 %idx
  %val = load i32, ptr addrspace(1) %gep, align 4
  store i32 %val, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_double_atomicrmw_i64(
; CHECK: %[[GEP_I64:[a-zA-Z0-9_]+]] = getelementptr i64, ptr addrspace(1) %buf, i32 %idx
; CHECK: atomicrmw xchg ptr addrspace(1) %[[GEP_I64]], i64 42 monotonic

define spir_kernel void @test_double_atomicrmw_i64(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %gep = getelementptr double, ptr addrspace(1) %buf, i32 %idx
  %old = atomicrmw xchg ptr addrspace(1) %gep, i64 42 monotonic
  ret void
}

declare spir_func i32 @_Z10atomic_addPU3AS1Vii(ptr addrspace(1), i32)
