; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[float]]
; CHECK-DAG: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[array]]
; CHECK-DAG: [[block_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
; CHECK-DAG: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
; CHECK-DAG: [[one:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
; CHECK-DAG: [[mask_sign:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
; CHECK-DAG: [[mask_abs:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
; CHECK-DAG: [[float_min_norm:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1.17549435e-38
; CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[block_ptr]] StorageBuffer
; CHECK: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[zero]]
; CHECK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[gep0]]
; CHECK: [[cast1:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld0]]
; CHECK: [[and1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast1]] [[mask_sign]]
; CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and1]]
; CHECK: [[cast2:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld0]]
; CHECK: [[and2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast2]] [[mask_abs]]
; CHECK: [[abs:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and2]]
; CHECK: [[cond:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs]] [[float_min_norm]]
; CHECK: [[res:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[cond]] [[sign]] [[ld0]]
; CHECK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[one]]
; CHECK: OpStore [[gep2]] [[res]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %1 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %ld1 = load float, ptr addrspace(1) %1, align 4
  %res = call float @llvm.canonicalize.f32(float %ld1)
  %2 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  store float %res, ptr addrspace(1) %2, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x float] })


!8 = !{i32 2}


