; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int]]
; CHECK-DAG: [[func_ty:%[a-zA-Z0-9_]+]] = OpTypeFunction [[int]] [[ptr]]
; CHECK: OpFunction [[int]] None [[func_ty]]
; CHECK: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[ptr]]
; CHECK: OpLoad [[int]] [[param]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_func i32 @foo(ptr addrspace(1) nocapture readonly %x) {
entry:
  %0 = load i32, ptr addrspace(1) %x, align 4
  %add = add nsw i32 %0, 1
  ret i32 %add
}

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture readonly align 4 %in, ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !9 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func i32 @foo(ptr addrspace(1) %1)
  store i32 %call, ptr addrspace(1) %3, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!9 = !{i32 2}

