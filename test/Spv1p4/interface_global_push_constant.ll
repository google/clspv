; RUN: clspv-opt -SPIRVProducerPass %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "foo" [[pc:%[a-zA-Z0-9_]+]]
; CHECK: [[pc]] = OpVariable {{.*}} PushConstant

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo() !clspv.pod_args_impl !1 !reqd_work_group_size !2 {
entry:
  ret void
}

!0 = !{i32 4}
!1 = !{i32 3}
!2 = !{i32 1, i32 1, i32 1}
