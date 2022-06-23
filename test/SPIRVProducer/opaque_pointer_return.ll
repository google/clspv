; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[int2:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 2
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int2]]
; CHECK: [[func_ty:%[a-zA-Z0-9_]+]] = OpTypeFunction [[ptr]] [[ptr]]
; CHECK: OpFunction [[ptr]] None [[func_ty]]
; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr]]
; CHECK: OpReturnValue [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_func ptr addrspace(1) @foo(ptr addrspace(1) readnone %x) {
entry:
  %arrayidx = getelementptr inbounds <2 x i32>, ptr addrspace(1) %x, i32 2
  ret ptr addrspace(1) %arrayidx
}

define dso_local spir_kernel void @test(ptr addrspace(1) writeonly align 8 %data) !clspv.pod_args_impl !9 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <2 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <2 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %call = tail call spir_func ptr addrspace(1) @foo(ptr addrspace(1) %1) #2
  store <2 x i32> <i32 42, i32 42>, ptr addrspace(1) %call, align 8
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x i32>] })

!9 = !{i32 2}

