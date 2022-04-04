; RUN: clspv-opt -SPIRVProducerPass %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4 -uniform-workgroup-size
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK-DAG: OpEntryPoint GLCompute %{{.*}} "foo" [[foo_wg:%[a-zA-Z0-9_]+]]
; CHECK-DAG: OpEntryPoint GLCompute %{{.*}} "bar" [[bar_wg:%[a-zA-Z0-9_]+]]
; CHECK-DAG: [[foo_wg]] = OpVariable {{.*}} Workgroup
; CHECK-DAG: [[bar_wg]] = OpVariable {{.*}} Workgroup

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(i32 addrspace(3)* %data) !clspv.pod_args_impl !1 !reqd_work_group_size !2 {
entry:
  %0 = call [0 x i32] addrspace(3)* @_Z11clspv.local.3(i32 3)
  %gep = getelementptr [0 x i32], [0 x i32] addrspace(3)* %0, i32 0, i32 0
  ret void
}

define spir_kernel void @bar(float addrspace(3)* %data) !clspv.pod_args_impl !1 !reqd_work_group_size !2 {
entry:
  %0 = call [0 x float] addrspace(3)* @_Z11clspv.local.4(i32 4)
  %gep = getelementptr [0 x float], [0 x float] addrspace(3)* %0, i32 0, i32 0
  ret void
}

declare [0 x i32] addrspace(3)* @_Z11clspv.local.3(i32)
declare [0 x float] addrspace(3)* @_Z11clspv.local.4(i32)

!_Z20clspv.local_spec_ids = !{!3, !4}
!clspv.next_spec_constant_id = !{!5}
!clspv.spec_constant_list = !{!6, !7}

!1 = !{i32 2}
!2 = !{i32 1, i32 1, i32 1}
!3 = !{void (i32 addrspace(3)*)* @foo, i32 0, i32 3}
!4 = !{void (float addrspace(3)*)* @bar, i32 0, i32 4}
!5 = distinct !{i32 4}
!6 = !{i32 3, i32 3}
!7 = !{i32 3, i32 4}

