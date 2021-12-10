; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test1() {
entry:
  %ptr = load <8 x float> addrspace(1)*, <8 x float> addrspace(1)** undef, align 4
  %data = getelementptr inbounds <8 x float>, <8 x float> addrspace(1)* %ptr, i32 undef
  ret void
}

define dso_local spir_kernel void @test2([1 x <16 x half>] addrspace(1)* %in, <16 x half> addrspace(1)* %out) {
  %ptr = getelementptr inbounds [1 x <16 x half>], [1 x <16 x half>] addrspace(1)* %in, i32 0, i32 undef
  %vec = load <16 x half>, <16 x half> addrspace(1)* %ptr, align 32
  store <16 x half> %vec, <16 x half> addrspace(1)* %out, align 32
  ret void
}

define dso_local spir_kernel void @test3([2 x [3 x <8 x i16>]] addrspace(1)* %in, <8 x i16> addrspace(1)* %out) {
  %ptr = getelementptr inbounds [2 x [3 x <8 x i16>]], [2 x [3 x <8 x i16>]] addrspace(1)* %in, i32 0, i32 1, i32 undef
  %vec = load <8 x i16>, <8 x i16> addrspace(1)* %ptr, align 32
  store <8 x i16> %vec, <8 x i16> addrspace(1)* %out, align 32
  ret void
}

@global = external dso_local addrspace(3) global [1 x <8 x float>], align 32

; This test covers ConstantExpr.
define dso_local spir_kernel void @test4(<8 x float> addrspace(1)* %out) {
  %ptr = getelementptr [1 x <8 x float>], [1 x <8 x float>] addrspace(3)* @global, i32 0, i32 undef
  %vec = load <8 x float>, <8 x float> addrspace(3)* %ptr, align 32
  store <8 x float> %vec, <8 x float> addrspace(1)* %out, align 32
  ret void
}

; This test covers ConstantExpr.
define dso_local spir_kernel void @test5(<8 x float> addrspace(1)* %out) {
  %ptr = getelementptr inbounds [1 x <8 x float>], [1 x <8 x float>] addrspace(3)* @global, i32 0, i32 0
  %vec = load <8 x float>, <8 x float> addrspace(3)* %ptr, align 32
  store <8 x float> %vec, <8 x float> addrspace(1)* %out, align 32
  ret void
}

; This test covers ConstantExpr.
define dso_local spir_kernel void @test6(<8 x float> addrspace(1)* %out) {
  %vec = load <8 x float>, <8 x float> addrspace(3)* getelementptr ([1 x <8 x float>], [1 x <8 x float>] addrspace(3)* @global, i32 0, i32 0), align 32
  store <8 x float> %vec, <8 x float> addrspace(1)* %out, align 32
  ret void
}

; CHECK: @global = external dso_local addrspace(3) global
; CHECK-SAME: [1 x [[FLOAT8:\[8 x float\]]]], align 32

; CHECK-LABEL: @test6(
; CHECK: load [[FLOAT8]], [[FLOAT8]] addrspace(3)*
; CHECK-SAME: getelementptr inbounds ([1 x [[FLOAT8]]], [1 x [[FLOAT8]]] addrspace(3)* @global, i32 0, i32 0),
; CHECK-SAME: align 32

; CHECK-LABEL: @test5(
; CHECK: load [[FLOAT8]], [[FLOAT8]] addrspace(3)*
; CHECK-SAME: getelementptr inbounds ([1 x [[FLOAT8]]], [1 x [[FLOAT8]]] addrspace(3)* @global, i32 0, i32 0),
; CHECK-SAME: align 32

; CHECK-LABEL: @test4(
; CHECK: load [[FLOAT8]], [[FLOAT8]] addrspace(3)*
; CHECK-SAME: getelementptr ([1 x [[FLOAT8]]], [1 x [[FLOAT8]]] addrspace(3)* @global, i32 0, i32 undef),
; CHECK-SAME: align 32

; CHECK-LABEL: @test3(
; CHECK-SAME: [[TYPE:\[2 x \[3 x \[8 x i16\]\]\]]] addrspace(1)* [[IN:%[^,]+]],
; CHECK: [[PTR:%[^ ]+]] = getelementptr inbounds [[TYPE]], [[TYPE]] addrspace(1)* [[IN]], i32 0, i32 1, i32 undef
; CHECK: load [[SHORT8:\[8 x i16\]]], [[SHORT8]] addrspace(1)* [[PTR]], align 32

; CHECK-LABEL: @test2(
; CHECK-SAME: [1 x [[HALF8:\[16 x half\]]]]
; CHECK-SAME: addrspace(1)* [[IN:%[^,]+]],
; CHECK: [[PTR:%[^ ]+]] = getelementptr inbounds [1 x [[HALF8]]], [1 x [[HALF8]]] addrspace(1)* [[IN]], i32 0, i32 undef
; CHECK: load [[HALF8]], [[HALF8]] addrspace(1)* [[PTR]], align 32

; CHECK-LABEL: @test1
; CHECK: getelementptr inbounds [[FLOAT8]], [[FLOAT8]] addrspace(1)* {{%[^ ]+}}, i32 undef
