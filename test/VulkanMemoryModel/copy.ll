; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.5 -vulkan-memory-model
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

; CHECK-NOT: OpDecorate {{.*}} Coherent
; CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
; CHECK: [[uint_16:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16
; CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
; CHECK: OpStore {{.*}} {{.*}} Aligned|MakePointerAvailable|NonPrivatePointer 16 [[DEVICE_SCOPE]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { [4 x i32], <4 x float> }

@foo.mem = internal unnamed_addr addrspace(3) global [16 x %struct.S] undef, align 16
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(%struct.S addrspace(1)* %out) !clspv.pod_args_impl !1 {
entry:
  %res = call { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x %struct.S] } zeroinitializer)
  %gep_out = getelementptr { [0 x %struct.S] }, { [0 x %struct.S] } addrspace(1)* %res, i32 0, i32 0, i32 0
  %gep_mem = getelementptr [16 x %struct.S], [16 x %struct.S] addrspace(3)* @foo.mem, i32 0, i32 0
  call void @_Z17spirv.copy_memory.1(%struct.S addrspace(1)* %gep_out, %struct.S addrspace(3)* %gep_mem, i32 16, i32 16, i32 0)
  ret void
}

declare { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

declare void @_Z17spirv.copy_memory.1(%struct.S addrspace(1)*, %struct.S addrspace(3)*, i32, i32, i32)

!1 = !{i32 2}
