; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "foo" [[wg:%[a-zA-Z0-9_]+]]
; CHECK: [[wg]] = OpVariable {{.*}} Workgroup

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@mem = local_unnamed_addr addrspace(3) global i32 undef, align 4

define spir_kernel void @foo() !clspv.pod_args_impl !1 !reqd_work_group_size !2 {
entry:
  %ld = load i32, i32 addrspace(3)* @mem
  ret void
}


!1 = !{i32 2}
!2 = !{i32 1, i32 1, i32 1}
