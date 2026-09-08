; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file=%t.spv -physical-storage-buffers
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env spv1.3 %t.spv

; CHECK-NOT: OpCapability VariablePointers
; CHECK-NOT: OpCapability VariablePointersStorageBuffer
; CHECK: OpCapability PhysicalStorageBufferAddresses

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-unknown-vulkan"

define spir_kernel void @test_select({ i64, i64, i32 } %podargs) !clspv.pod_args_impl !10 !kernel_arg_map !11 {
entry:
  %0 = call ptr addrspace(9) @_Z14clspv.resource.0(i32 -1, i32 0, i32 5, i32 0, i32 0, i32 0, { { i64, i64, i32 } } zeroinitializer)
  %1 = getelementptr { { i64, i64, i32 } }, ptr addrspace(9) %0, i32 0, i32 0
  %2 = load { i64, i64, i32 }, ptr addrspace(9) %1, align 8
  %a_int = extractvalue { i64, i64, i32 } %2, 0
  %b_int = extractvalue { i64, i64, i32 } %2, 1
  %cond_int = extractvalue { i64, i64, i32 } %2, 2
  %a = inttoptr i64 %a_int to ptr addrspace(1), !clspv.pointer_from_pod !13
  %b = inttoptr i64 %b_int to ptr addrspace(1), !clspv.pointer_from_pod !13
  %cond = icmp eq i32 %cond_int, 0
  %ptr = select i1 %cond, ptr addrspace(1) %a, ptr addrspace(1) %b
  %v = load i32, ptr addrspace(1) %ptr, align 4
  store i32 %v, ptr addrspace(1) %a, align 4
  ret void
}

define spir_kernel void @test_phi({ i64, i64, i32 } %podargs) !clspv.pod_args_impl !10 !kernel_arg_map !11 {
entry:
  %0 = call ptr addrspace(9) @_Z14clspv.resource.0(i32 -1, i32 0, i32 5, i32 0, i32 0, i32 0, { { i64, i64, i32 } } zeroinitializer)
  %1 = getelementptr { { i64, i64, i32 } }, ptr addrspace(9) %0, i32 0, i32 0
  %2 = load { i64, i64, i32 }, ptr addrspace(9) %1, align 8
  %a_int = extractvalue { i64, i64, i32 } %2, 0
  %b_int = extractvalue { i64, i64, i32 } %2, 1
  %a = inttoptr i64 %a_int to ptr addrspace(1), !clspv.pointer_from_pod !13
  %b = inttoptr i64 %b_int to ptr addrspace(1), !clspv.pointer_from_pod !13
  br label %loop

loop:
  %phi = phi ptr addrspace(1) [ %a, %entry ], [ %b, %next ]
  %n = phi i32 [ 0, %entry ], [ %add, %next ]
  %cmp = icmp eq i32 %n, 0
  br i1 %cmp, label %next, label %exit

next:
  %add = add i32 %n, 1
  br label %loop

exit:
  %v = load i32, ptr addrspace(1) %phi, align 4
  store i32 %v, ptr addrspace(1) %a, align 4
  ret void
}

declare ptr addrspace(9) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { { i64, i64, i32 } })

!10 = !{i32 2}
!11 = !{!12}
!12 = !{!"", i32 0, i32 0, i32 0, i32 20, !"pod_pushconstant"}
!13 = !{}
