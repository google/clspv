; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpDecorate [[x:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[x]] Binding 0
; CHECK: OpDecorate [[x]] Coherent
; CHECK: OpDecorate [[y:%[a-zA-Z0-9_]+]] DescriptorSet 0
; CHECK: OpDecorate [[y]] Binding 1
; CHECK-NOT: OpDecorate [[y]] Coherent
; CHECK: OpDecorate [[param:%[a-zA-Z0-9_]+]] Coherent
; CHECK: [[param]] = OpFunctionParameter

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func void @bar(ptr addrspace(1) nocapture writeonly %x, i32 %y) {
entry:
  store i32 %y, ptr addrspace(1) %x, align 4
  ret void
}

define spir_kernel void @foo(ptr addrspace(1) nocapture align 4 %x, ptr addrspace(1) nocapture writeonly align 4 %y, { i32, i32 } %podargs) !clspv.pod_args_impl !16 !kernel_arg_map !17 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32, i32 } } zeroinitializer)
  %5 = getelementptr { { i32, i32 } }, ptr addrspace(9) %4, i32 0, i32 0
  %6 = load { i32, i32 }, ptr addrspace(9) %5, align 4
  %c = extractvalue { i32, i32 } %6, 0
  %7 = load i32, ptr addrspace(1) %1, align 4
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72)
  %tobool.i.not = icmp eq i32 %c, 0
  %y.x = select i1 %tobool.i.not, ptr addrspace(1) %3, ptr addrspace(1) %1
  %offset = extractvalue { i32, i32 } %6, 1
  %add.ptr.i = getelementptr inbounds i32, ptr addrspace(1) %y.x, i32 %offset
  tail call spir_func void @bar(ptr addrspace(1) %add.ptr.i, i32 %7)
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32, i32 } })

!16 = !{i32 2}
!17 = !{!18, !19, !20, !21}
!18 = !{!"x", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!19 = !{!"y", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!20 = !{!"c", i32 2, i32 2, i32 0, i32 4, !"pod_pushconstant"}
!21 = !{!"offset", i32 3, i32 2, i32 4, i32 4, !"pod_pushconstant"}

