; RUN: clspv-opt %s -o %t.ll --spv-version=1.4 --untyped-pointers --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: OpDecorate [[out:%[a-zA-Z0-9_]+]] Binding 1
; CHECK-DAG: OpDecorate [[in:%[a-zA-Z0-9_]+]] Binding 0
; CHECK-DAG: [[uint_64:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 64
; CHECK-DAG: [[uint_32:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 32
; CHECK: [[wg:%[a-zA-Z0-9_]+]] = OpUntypedVariableKHR {{%.*}} Workgroup

; CHECK: OpCopyMemorySized [[out]] [[in]] [[uint_64]] Aligned 16 Aligned 16
; CHECK: OpCopyMemorySized [[out]] [[wg]] [[uint_32]] Aligned 32 Aligned 8
; CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad
; CHECK: OpCopyMemorySized [[wg]] [[in]] [[ld]] Volatile|Aligned 16 Volatile|Aligned 16

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(3) align 16 %wg, ptr addrspace(1) align 16 %in, ptr addrspace(1) align 16 %out) !clspv.pod_args_impl !1 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, { [0 x i32] } zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 1, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 2, i32 1, i32 0, { [0 x <4 x float>] } zeroinitializer)
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %2, ptr addrspace(1) noundef align 16 dereferenceable(16) %1, i32 64, i1 false)
  tail call void @llvm.memcpy.p1.p3.i32(ptr addrspace(1) noundef align 32 dereferenceable(16) %2, ptr addrspace(3) noundef align 8 dereferenceable(16) %0, i32 32, i1 false)
  %ld = load i32, ptr addrspace(1) %1, align 4
  tail call void @llvm.memcpy.p3.p1.i32(ptr addrspace(3) noundef align 16 dereferenceable(16) %0, ptr addrspace(1) noundef align 16 dereferenceable(16) %1, i32 %ld, i1 true)
  ret void
}

declare void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noalias nocapture writeonly %0, ptr addrspace(1) noalias nocapture readonly %1, i32 %2, i1 immarg %3)
declare void @llvm.memcpy.p1.p3.i32(ptr addrspace(1) noalias nocapture writeonly %0, ptr addrspace(3) noalias nocapture readonly %1, i32 %2, i1 immarg %3)
declare void @llvm.memcpy.p3.p1.i32(ptr addrspace(3) noalias nocapture writeonly %0, ptr addrspace(1) noalias nocapture readonly %1, i32 %2, i1 immarg %3)
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })
declare ptr addrspace(3) @_Z11clspv.local.3(i32, { [0 x i32] })

!clspv.descriptor.index = !{!4}
!clspv.next_spec_constant_id = !{!5}
!clspv.spec_constant_list = !{!6}
!_Z20clspv.local_spec_ids = !{!7}

!1 = !{i32 2}
!4 = !{i32 1}
!5 = distinct !{i32 4}
!6 = !{i32 3, i32 3}
!7 = !{ptr @test, i32 0, i32 3}

