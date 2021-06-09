; RUN: clspv-opt -SPIRVProducerPass %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
; CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-DAG: [[true:%[a-zA-Z0-9_]+]] = OpConstantTrue [[bool]]
; CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[int4]]
; CHECK: [[ld2:%[a-zA-Z0-9_]+]] = OpLoad [[int4]]
; CHECK: OpSelect [[int4]] [[true]] [[ld1]] [[ld2]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @copy(i32 addrspace(1)* nocapture readonly %in, i32 addrspace(1)* nocapture %out) !clspv.pod_args_impl !9 {
entry:
  %0 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0)
  %1 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0)
  %3 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %2, i32 0, i32 0, i32 0
  %4 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0)
  %5 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %0, i32 0, i32 0, i32 1
  %6 = load <4 x i32>, <4 x i32> addrspace(1)* %1, align 4
  %7 = load <4 x i32>, <4 x i32> addrspace(1)* %5, align 4
  %8 = select i1 true, <4 x i32> %6, <4 x i32> %7
  store <4 x i32> %8, <4 x i32> addrspace(1)* %3, align 4
  ret void
}

declare { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32)

declare { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32)

!9 = !{i32 2}

