; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4 -max-pushconstant-size=8
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpDecorate {{.*}} Block
; CHECK: OpDecorate [[pod_struct:%[a-zA-Z0-9_]+]] Block
; CHECK: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
; CHECK: [[pod_struct_members:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ulong]] [[ulong]]
; CHECK: [[pod_struct]] = OpTypeStruct [[pod_struct_members]]
; CHECK: [[pod_struct_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Uniform [[pod_struct]]
; CHECK: OpVariable [[pod_struct_ptr]] Uniform

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @sample_test(i64 addrspace(1)* nocapture %result, { i64, i64 } %podargs) !clspv.pod_args_impl !4 !kernel_arg_map !9 {
entry:
  %0 = call { [0 x i64] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i64] } zeroinitializer)
  %1 = getelementptr { [0 x i64] }, { [0 x i64] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call { { i64, i64 } } addrspace(6)* @_Z14clspv.resource.1(i32 0, i32 1, i32 4, i32 1, i32 1, i32 0, { { i64, i64 } } zeroinitializer)
  %3 = getelementptr { { i64, i64 } }, { { i64, i64 } } addrspace(6)* %2, i32 0, i32 0
  %4 = load { i64, i64 }, { i64, i64 } addrspace(6)* %3, align 8
  %arg0 = extractvalue { i64, i64 } %4, 0
  %arg1 = extractvalue { i64, i64 } %4, 1
  %add.i = add nsw i64 %arg0, %arg1
  store i64 %add.i, i64 addrspace(1)* %1, align 8
  ret void
}

declare { [0 x i64] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i64] })

declare { { i64, i64 } } addrspace(6)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { { i64, i64 } })

!clspv.descriptor.index = !{!4}

!4 = !{i32 1}
!9 = !{!10, !11, !12}
!10 = !{!"result", i32 2, i32 0, i32 0, i32 0, !"buffer"}
!11 = !{!"arg0", i32 0, i32 1, i32 0, i32 8, !"pod_ubo"}
!12 = !{!"arg1", i32 1, i32 1, i32 8, i32 8, !"pod_ubo"}
