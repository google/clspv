; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv -int8=0
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
; CHECK-DAG: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
; CHECK-DAG: [[int_const_255:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 255

; CHECK: [[load:%[a-zA-Z0-9_]+]] = OpLoad [[int]]
; CHECK: [[zext32:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[load]] [[int_const_255]]
; CHECK: OpStore {{.*}} [[zext32]]

; CHECK: [[mask16:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[load]] [[int_const_255]]
; CHECK: [[zext16:%[a-zA-Z0-9_]+]] = OpUConvert [[short]] [[mask16]]
; CHECK: OpStore {{.*}} [[zext16]]

; CHECK: [[mask64:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[load]] [[int_const_255]]
; CHECK: [[zext64:%[a-zA-Z0-9_]+]] = OpUConvert [[long]] [[mask64]]
; CHECK: OpStore {{.*}} [[zext64]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spirv32-unknown-vulkan"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite)
define dso_local spir_kernel void @test(ptr addrspace(1) readonly align 1 captures(none) %in, ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %out, ptr addrspace(1) writeonly align 2 captures(none) initializes((0, 2)) %out16, ptr addrspace(1) writeonly align 8 captures(none) initializes((0, 8)) %out64) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i8] } zeroinitializer)
  %1 = getelementptr { [0 x i8] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i16] } zeroinitializer)
  %5 = getelementptr { [0 x i16] }, ptr addrspace(1) %4, i32 0, i32 0, i32 0
  %6 = call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x i64] } zeroinitializer)
  %7 = getelementptr { [0 x i64] }, ptr addrspace(1) %6, i32 0, i32 0, i32 0
  %8 = load i8, ptr addrspace(1) %1, align 1
  %conv.i = zext i8 %8 to i32
  store i32 %conv.i, ptr addrspace(1) %3, align 4
  %conv.i16 = zext i8 %8 to i16
  store i16 %conv.i16, ptr addrspace(1) %5, align 2
  %conv.i64 = zext i8 %8 to i64
  store i64 %conv.i64, ptr addrspace(1) %7, align 8
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x i16] })

declare ptr addrspace(1) @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { [0 x i64] })
