; RUN: clspv-opt -SPIRVProducerPass %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "foo" [[var:%[a-zA-Z0-9_]+]]
; CHECK: [[var]] = OpVariable {{.*}} PushConstant

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo({ float, float } %podargs)!reqd_work_group_size !8 !clspv.pod_args_impl !9 !kernel_arg_map !10 {
entry:
  %0 = call { { float, float } } addrspace(9)* @_Z14clspv.resource.0(i32 -1, i32 0, i32 5, i32 0, i32 0, i32 0)
  %1 = getelementptr { { float, float } }, { { float, float } } addrspace(9)* %0, i32 0, i32 0
  %2 = load { float, float }, { float, float } addrspace(9)* %1, align 4
  ret void
}

declare { { float, float } } addrspace(9)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32)

!8 = !{i32 1, i32 1, i32 1}
!9 = !{i32 2}
!10 = !{!11, !12}
!11 = !{!"x", i32 0, i32 0, i32 0, i32 4, !"pod_pushconstant"}
!12 = !{!"y", i32 1, i32 0, i32 4, i32 4, !"pod_pushconstant"}
