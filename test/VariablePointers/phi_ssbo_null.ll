; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; VariablePointersStorageBuffer required because phi has a single buffer.
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpCapability VariablePointersStorageBuffer
; CHECK-NOT: OpCapability VariablePointers
; CHECK: OpExtension "SPV_KHR_variable_pointers"
; CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
; CHECK: OpPhi [[ptr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture readonly align 4 %in, ptr addrspace(1) nocapture writeonly align 4 %out, { i32 } %podargs) !clspv.pod_args_impl !14 !kernel_arg_map !15 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %5 = getelementptr { { i32 } }, ptr addrspace(9) %4, i32 0, i32 0
  %6 = load { i32 }, ptr addrspace(9) %5, align 4
  %a = extractvalue { i32 } %6, 0
  %cmp.i = icmp eq i32 %a, 0
  br i1 %cmp.i, label %if.then.i, label %foo.inner.exit

if.then.i:                                        ; preds = %entry
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 72)
  br label %foo.inner.exit

foo.inner.exit:                                   ; preds = %if.then.i, %entry
  %storemerge.in = phi ptr addrspace(1) [ null, %entry ], [ %1, %if.then.i ]
  %storemerge = load i32, ptr addrspace(1) %storemerge.in, align 4
  store i32 %storemerge, ptr addrspace(1) %3, align 4
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!14 = !{i32 2}
!15 = !{!16, !17, !18}
!16 = !{!"in", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!17 = !{!"out", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!18 = !{!"a", i32 2, i32 2, i32 0, i32 4, !"pod_pushconstant"}

