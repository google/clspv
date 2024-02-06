; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK-NOT: OpCapability VariablePointers
; CHECK-NOT: OpExtension "SPV_KHR_variable_pointers"
; CHECK-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage
; CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
; CHECK: OpFunctionParameter [[image]]
; CHECK: OpFunctionParameter [[sampler]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define spir_func <4 x float> @bar(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %image, target("spirv.Sampler") %sampler) {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %image, target("spirv.Sampler") %sampler, <2 x float> zeroinitializer)
  ret <4 x float> %call
}

define spir_kernel void @foo(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %image, target("spirv.Sampler") %sampler, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !17 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) undef)
  %1 = call target("spirv.Sampler") @_Z14clspv.resource.1(i32 0, i32 1, i32 8, i32 1, i32 1, i32 0, target("spirv.Sampler") zeroinitializer)
  %2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %3 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x float> @bar(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %1) #4
  store <4 x float> %call, ptr addrspace(1) %3, align 16
  ret void
}

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

declare target("spirv.Sampler") @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Sampler"))

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

!17 = !{i32 2}

