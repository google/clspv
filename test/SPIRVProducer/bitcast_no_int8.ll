; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv -int8=0
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[int_const_24:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 24

; CHECK: [[load:%[a-zA-Z0-9_]+]] = OpLoad [[int]]

; CHECK: [[shl:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[int]] [[load]] [[int_const_24]]
; CHECK: [[sext:%[a-zA-Z0-9_]+]] = OpShiftRightArithmetic [[int]] [[shl]] [[int_const_24]]
; CHECK: OpStore {{.*}} [[sext]]

; CHECK: [[shl1:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[int]] [[load]] [[int_const_24]]
; CHECK: [[sext1:%[a-zA-Z0-9_]+]] = OpShiftRightArithmetic [[int]] [[shl1]] [[int_const_24]]
; CHECK: [[conv1_i:%[a-zA-Z0-9_]+]] = OpConvertSToF [[float]] [[sext1]]
; CHECK: OpStore {{.*}} [[conv1_i]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn denormal_fpenv(dynamic) memory(argmem: readwrite)
define dso_local spir_kernel void @test(ptr addrspace(1) readonly align 1 captures(none) %in, ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %out_a, ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %out_b) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i8] } zeroinitializer)
  %1 = getelementptr { [0 x i8] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %5 = getelementptr { [0 x float] }, ptr addrspace(1) %4, i32 0, i32 0, i32 0
  %6 = load i8, ptr addrspace(1) %1, align 1
  %conv.i = sext i8 %6 to i32
  store i32 %conv.i, ptr addrspace(1) %3, align 4
  %conv1.i = sitofp i8 %6 to float
  store float %conv1.i, ptr addrspace(1) %5, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x float] })
