; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "test" [[sampler:%[a-zA-Z0-9_]+]]
; CHECK: [[sampler_type:%[a-zA-Z0-9_]+]] = OpTypeSampler
; CHECK: [[sampler_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[sampler_type]]
; CHECK: [[sampler]] = OpVariable [[sampler_ptr]] UniformConstant

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define spir_kernel void @test(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %img, <4 x float> addrspace(1)* nocapture %out) !clspv.pod_args_impl !4 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 1, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) undef)
  %1 = call { [0 x <4 x float>] } addrspace(1)* @_Z14clspv.resource.1(i32 1, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %2 = getelementptr { [0 x <4 x float>] }, { [0 x <4 x float>] } addrspace(1)* %1, i32 0, i32 0, i32 0
  %3 = call target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 16, target("spirv.Sampler") zeroinitializer)
  %4 = tail call <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %3, <2 x float> <float 1.000000e+00, float 2.000000e+00>)
  store <4 x float> %4, <4 x float> addrspace(1)* %2, align 16
  ret void
}

declare target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32, i32, i32, target("spirv.Sampler"))

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

declare { [0 x <4 x float>] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

!clspv.descriptor.index = !{!4}

!4 = !{i32 2}
