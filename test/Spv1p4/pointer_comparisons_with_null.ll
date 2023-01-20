; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-DAG: [[uint_15:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 15
; CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
; CHECK-DAG: [[uint_storage_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
; CHECK-DAG: [[null:%[a-zA-Z0-9_]+]] = OpConstantNull [[uint_storage_ptr]]
; CHECK: [[addr:%[a-zA-Z0-9_]+]] = OpAccessChain [[uint_storage_ptr]] {{.*}} [[uint_0]] [[uint_15]]
; CHECK: OpPtrEqual [[bool]] [[addr]] [[null]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @test(ptr addrspace(1) nocapture readnone %ptr0, ptr addrspace(1) nocapture %out, { i32 } %podargs) local_unnamed_addr !clspv.pod_args_impl !9 !kernel_arg_map !10 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %2 = getelementptr { [0 x i32] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0
  %3 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %4 = getelementptr { { i32 } }, { { i32 } } addrspace(9)* %3, i32 0, i32 0
  %5 = load { i32 }, ptr addrspace(9) %4, align 4
  %val = extractvalue { i32 } %5, 0
  %cmp.i = icmp ne i32 %val, 68
  %6 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 15
  %phi.cmp = icmp eq ptr addrspace(1) %6, null
  %ptr.i.0 = select i1 %cmp.i, i1 true, i1 %phi.cmp
  br i1 %ptr.i.0, label %if.then2.i, label %test.inner.exit

if.then2.i:                                       ; preds = %entry
  store i32 13, i32 addrspace(1)* %2, align 4
  br label %test.inner.exit

test.inner.exit:                                  ; preds = %if.then2.i, %entry
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!clspv.descriptor.index = !{!4}

!4 = !{i32 1}
!9 = !{i32 2}
!10 = !{!11, !12, !13}
!11 = !{!"ptr0", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!12 = !{!"out", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!13 = !{!"val", i32 2, i32 2, i32 0, i32 4, !"pod_pushconstant"}

