; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpCopyMemory %{{.*}} %{{.*}} Aligned 16 Aligned 16

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { [4 x float], <4 x i32> }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(%struct.S addrspace(1)* nocapture %out, %struct.S addrspace(1)* nocapture readonly %in)!clspv.pod_args_impl !9 {
entry:
  %0 = call { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.S] } zeroinitializer)
  %1 = getelementptr { [0 x %struct.S] }, { [0 x %struct.S] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x %struct.S] } zeroinitializer)
  %3 = getelementptr { [0 x %struct.S] }, { [0 x %struct.S] } addrspace(1)* %2, i32 0, i32 0, i32 0
  call void @_Z17spirv.copy_memory(%struct.S addrspace(1)* %1, %struct.S addrspace(1)* %3, i32 16, i32 16, i32 0)
  ret void
}

declare void @llvm.memcpy.p1i8.p1i8.i32(i8 addrspace(1)* noalias nocapture writeonly, i8 addrspace(1)* noalias nocapture readonly, i32, i1 immarg)

declare void @_Z17spirv.copy_memory(%struct.S addrspace(1)*, %struct.S addrspace(1)*, i32, i32, i32)

declare { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

declare { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

!9 = !{i32 2}

