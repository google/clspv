; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.5 -vulkan-memory-model
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

; CHECK-NOT: OpDecorate {{.*}} Coherent
; CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
; CHECK: [[DEVICE_SCOPE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1
; CHECK: {{.*}} = OpLoad {{.*}} {{.*}} MakePointerVisible|NonPrivatePointer [[DEVICE_SCOPE]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { [4 x i32], <4 x float> }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(%struct.S addrspace(1)* %in) !clspv.pod_args_impl !1 {
entry:
  %res = call { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x %struct.S] } zeroinitializer)
  %gep = getelementptr { [0 x %struct.S] }, { [0 x %struct.S] } addrspace(1)* %res, i32 0, i32 0, i32 0
  %ld = load %struct.S, %struct.S addrspace(1)* %gep
  ret void
}

declare { [0 x %struct.S] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

!1 = !{i32 2}

