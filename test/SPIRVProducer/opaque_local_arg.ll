; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 1 Offset 16
; CHECK: OpDecorate [[size:%[a-zA-Z0-9_]+]] SpecId 3
; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
; CHECK-DAG: [[struct]] = OpTypeStruct [[int4]] [[float4]]
; CHECK-DAG: [[alt_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[int4]] [[float4]]
; CHECK-DAG: [[size]] = OpSpecConstant [[int]]
; CHECK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeArray [[alt_struct]] [[size]]
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[array]]
; CHECK: OpVariable [[ptr]] Workgroup

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { <4 x i32>, <4 x float> }

@__spirv_LocalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @test(ptr addrspace(3) nocapture align 16 %wg, ptr addrspace(1) nocapture readonly align 16 %in1, ptr addrspace(1) nocapture readonly align 16 %in2, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !13 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x %struct.S] zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 1, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 2, i32 1, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %3 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 3, i32 2, i32 0, { [0 x %struct.S] } zeroinitializer)
  %gep = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_LocalInvocationId, i32 0, i32 0
  %4 = load i32, ptr addrspace(5) %gep, align 4
  %5 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %1, i32 0, i32 0, i32 %4
  %6 = load <4 x i32>, ptr addrspace(1) %5, align 16
  %7 = getelementptr [0 x %struct.S], ptr addrspace(3) %0, i32 0, i32 %4, i32 0
  store <4 x i32> %6, ptr addrspace(3) %7, align 16
  %8 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 %4
  %9 = load <4 x float>, ptr addrspace(1) %8, align 16
  %10 = getelementptr [0 x %struct.S], ptr addrspace(3) %0, i32 0, i32 %4, i32 1
  store <4 x float> %9, ptr addrspace(3) %10, align 16
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264)
  %11 = load <4 x i32>, ptr addrspace(3) %7, align 16
  %12 = getelementptr { [0 x %struct.S] }, ptr addrspace(1) %3, i32 0, i32 0, i32 %4, i32 0
  store <4 x i32> %11, ptr addrspace(1) %12, align 16
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) local_unnamed_addr
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })
declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })
declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x %struct.S])

!clspv.descriptor.index = !{!4}
!clspv.next_spec_constant_id = !{!5}
!clspv.spec_constant_list = !{!6}
!_Z20clspv.local_spec_ids = !{!7}

!4 = !{i32 1}
!5 = distinct !{i32 4}
!6 = !{i32 3, i32 3}
!7 = !{ptr @test, i32 0, i32 3}
!13 = !{i32 2}

