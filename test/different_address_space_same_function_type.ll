; RUN: clspv-opt %s --passes=spirv-producer --producer-out-file %t.spv -o %t.ll
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; #651: Since __constant and __global are both mapped to StorageBuffer storage
; class, ensure the function type for the helpers is correctly unique.
;
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[ptr_ssbo_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
; CHECK: OpTypeFunction [[float]] [[ptr_ssbo_float]]
; CHECK-NOT: OpTypeFunction [[float]] [[ptr_ssbo_float]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @baz(ptr addrspace(1) nocapture readonly align 4 %in1, ptr addrspace(2) nocapture readonly align 4 %in2, ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !10 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %1 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %3 = getelementptr { [0 x float] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %5 = getelementptr { [0 x float] }, ptr addrspace(1) %4, i32 0, i32 0, i32 0
  %call0 = tail call spir_func float @foo(ptr addrspace(1) %1)
  store float %call0, ptr addrspace(1) %5, align 4
  %in2.val = load float, ptr addrspace(2) %3, align 4
  %call1 = tail call spir_func float @bar(ptr addrspace(2) %3)
  %6 = getelementptr { [0 x float] }, ptr addrspace(1) %4, i32 0, i32 0, i32 1
  store float %call1, ptr addrspace(1) %6, align 4
  ret void
}

define internal spir_func float @foo(ptr addrspace(1) %p) unnamed_addr {
entry:
  %ld = load float, ptr addrspace(1) %p
  ret float %ld
}

define internal spir_func float @bar(ptr addrspace(2) %p) unnamed_addr {
entry:
  %ld = load float, ptr addrspace(2) %p
  ret float %ld
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x float] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x float] })

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x float] })

!10 = !{i32 2}

