; RUN: clspv-opt %s -o %t.ll -producer-out-file=%t.spv --passes=spirv-producer -physical-storage-buffers
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK-DAG: OpDecorate [[array:%[a-zA-Z0-9_]+]] ArrayStride 16
; CHECK-DAG: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 1 Offset 256
; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[int_16:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 16
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
; CHECK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeArray [[float4]] [[int_16]]
; CHECK-DAG: [[struct]] = OpTypeStruct [[array]] [[int]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%struct.TestStruct = type { [16 x <4 x float>], i32 }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @test_buffer_read_struct({ i64 } %podargs) !clspv.pod_args_impl !10 !kernel_arg_map !11 {
entry:
  %0 = call ptr addrspace(9) @_Z14clspv.resource.0(i32 -1, i32 0, i32 5, i32 0, i32 0, i32 0, { { i64 } } zeroinitializer)
  %1 = getelementptr { { i64 } }, ptr addrspace(9) %0, i32 0, i32 0
  %2 = load { i64 }, ptr addrspace(9) %1, align 8
  %3 = extractvalue { i64 } %2, 0
  %4 = inttoptr i64 %3 to ptr addrspace(1), !clspv.pointer_from_pod !13
  store %struct.TestStruct zeroinitializer, ptr addrspace(1) %4, align 4
  ret void
}

declare ptr addrspace(9) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { { i64 } })

!10 = !{i32 2}
!11 = !{!12}
!12 = !{!"", i32 0, i32 0, i32 0, i32 8, !"pointer_pushconstant"}
!13 = !{}

