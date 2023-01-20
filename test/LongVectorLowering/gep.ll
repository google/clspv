; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test1() {
entry:
  %ptr = load ptr addrspace(1), ptr undef
  %data = getelementptr inbounds <8 x float>, ptr addrspace(1) %ptr, i32 undef
  ret void
}

define dso_local spir_kernel void @test2(ptr addrspace(1) %in, ptr addrspace(1) %out) {
  %ptr = getelementptr inbounds [1 x <16 x half>], ptr addrspace(1) %in, i32 0, i32 undef
  %vec = load <16 x half>, ptr addrspace(1) %ptr, align 32
  store <16 x half> %vec, ptr addrspace(1) %out, align 32
  ret void
}

define dso_local spir_kernel void @test3(ptr addrspace(1) %in, ptr addrspace(1) %out) {
  %ptr = getelementptr inbounds [2 x [3 x <8 x i16>]], ptr addrspace(1) %in, i32 0, i32 1, i32 undef
  %vec = load <8 x i16>, ptr addrspace(1) %ptr, align 32
  store <8 x i16> %vec, ptr addrspace(1) %out, align 32
  ret void
}

@global = external dso_local addrspace(3) global [1 x <8 x float>], align 32

; This test covers ConstantExpr.
define dso_local spir_kernel void @test4(ptr addrspace(1) %out) {
  %ptr = getelementptr [1 x <8 x float>], ptr addrspace(3) @global, i32 0, i32 undef
  %vec = load <8 x float>, ptr addrspace(3) %ptr, align 32
  store <8 x float> %vec, ptr addrspace(1) %out, align 32
  ret void
}

; This test covers ConstantExpr.
define dso_local spir_kernel void @test5(ptr addrspace(1) %out) {
  %ptr = getelementptr inbounds [1 x <8 x float>], ptr addrspace(3) @global, i32 0, i32 0
  %vec = load <8 x float>, ptr addrspace(3) %ptr, align 32
  store <8 x float> %vec, ptr addrspace(1) %out, align 32
  ret void
}

; This test covers ConstantExpr.
define dso_local spir_kernel void @test6(ptr addrspace(1) %out) {
  %vec = load <8 x float>, ptr addrspace(3) getelementptr ([1 x <8 x float>], ptr addrspace(3) @global, i32 0, i32 0), align 32
  store <8 x float> %vec, ptr addrspace(1) %out, align 32
  ret void
}

; CHECK: [[global:@[a-zA-Z0-9_.]+]] = external dso_local addrspace(3) global
; CHECK-SAME: [1 x [[FLOAT8:\[8 x float\]]]], align 32

; CHECK-LABEL: @test1
; CHECK: getelementptr inbounds [[FLOAT8]], ptr addrspace(1) %{{.*}}, i32 undef

; CHECK-LABEL: @test2(
; CHECK-SAME: ptr addrspace(1) [[IN:%[^,]+]],
; CHECK: [[PTR:%[^ ]+]] = getelementptr inbounds [1 x [16 x half]], ptr addrspace(1) [[IN]], i32 0, i32 undef
; CHECK: load [16 x half], ptr addrspace(1) [[PTR]], align 32

; CHECK-LABEL: @test3(
; CHECK-SAME: ptr addrspace(1) [[IN:%[^,]+]],
; CHECK: [[PTR:%[^ ]+]] = getelementptr inbounds [[TYPE:\[2 x \[3 x \[8 x i16\]\]\]]], ptr addrspace(1) [[IN]], i32 0, i32 1, i32 undef
; CHECK: load [[SHORT8:\[8 x i16\]]], ptr addrspace(1) [[PTR]], align 32

; CHECK-LABEL: @test4(
; CHECK: load [[FLOAT8]], ptr addrspace(3) [[global]]

; CHECK-LABEL: @test5(
; CHECK: load [[FLOAT8]], ptr addrspace(3) [[global]]

; CHECK-LABEL: @test6(
; CHECK: load [[FLOAT8]], ptr addrspace(3) [[global]]
