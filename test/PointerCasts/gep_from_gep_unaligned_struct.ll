; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.P = type { i8, [7 x i8], <2 x i32> }

; CHECK-LABEL: define spir_kernel void @test_select_upgradeable_constant_casts(
; CHECK: [[pts:%[a-zA-Z0-9_.]+]] = alloca [2 x %struct.P]
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 0, i32 2, i32 0
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 0, i32 1, i32 6
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 %cmp, ptr [[gep1]], ptr [[gep0]]
define spir_kernel void @test_select_upgradeable_constant_casts(ptr addrspace(1) %out, i32 %i, i1 %cmp) {
entry:
  %pts = alloca [2 x %struct.P], align 8
  %d = getelementptr [2 x %struct.P], ptr %pts, i32 0, i32 %i, i32 0
  store i8 0, ptr %d, align 8
  %a = getelementptr i8, ptr %pts, i32 8
  %b = getelementptr i8, ptr %a, i32 -1
  %sel = select i1 %cmp, ptr %b, ptr %a
  %l = load i8, ptr %sel, align 1
  store i8 %l, ptr addrspace(1) %out, align 1
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_gep_from_gep_unaligned(
; CHECK: [[pts2:%[a-zA-Z0-9_.]+]] = alloca [24 x i8]
; CHECK: [[gep_unaligned:%[a-zA-Z0-9_.]+]] = getelementptr [24 x i8], ptr [[pts2]], i32 0, i32 5
; CHECK: load i8, ptr [[gep_unaligned]], align 1
define spir_kernel void @test_gep_from_gep_unaligned(ptr addrspace(1) %out, i32 %i) {
entry:
  %pts = alloca [6 x i32], align 4
  %d = getelementptr [6 x i32], ptr %pts, i32 0, i32 %i
  store i32 0, ptr %d, align 4
  %a = getelementptr i8, ptr %pts, i32 4
  %b = getelementptr i8, ptr %a, i32 1
  %l = load i8, ptr %b, align 1
  store i8 %l, ptr addrspace(1) %out, align 1
  ret void
}
