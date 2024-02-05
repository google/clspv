; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env vulkan1.0
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[var]] Binding 0
; CHECK: OpDecorate [[var]] Coherent
; CHECK: OpDecorate [[param1:%[a-zA-Z0-9_]+]] Coherent
; CHECK: OpDecorate [[param2:%[a-zA-Z0-9_]+]] Coherent
; CHECK: [[baz:%[a-zA-Z0-9_]+]] = OpFunction
; CHECK: [[param1]] = OpFunctionParameter
; CHECK: = OpFunction
; CHECK: [[param2]] = OpFunctionParameter
; CHECK: OpFunctionCall {{.*}} [[baz]] [[param2]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func i32 @baz(ptr addrspace(1) nocapture readonly %x) {
entry:
  %0 = load i32, ptr addrspace(1) %x, align 4
  ret i32 %0
}

define dso_local spir_func i32 @bar(ptr addrspace(1) nocapture readonly %x) {
entry:
  %call = tail call spir_func i32 @baz(ptr addrspace(1) %x)
  ret i32 %call
}

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture align 4 %data) !clspv.pod_args_impl !16 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %call = tail call spir_func i32 @bar(ptr addrspace(1) %1)
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72)
  %2 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  store i32 %call, ptr addrspace(1) %2, align 4
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!16 = !{i32 2}

