; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "foo" [[sampler_var:%[a-zA-Z0-9_]+]]
; CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[sampler_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[sampler]]
; CHECK-DAG: [[sampler_var]] = OpVariable [[sampler_ptr]] UniformConstant

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define void @bar(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %img) {
entry:
  %0 = call target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 18, target("spirv.Sampler") zeroinitializer)
  %1 = tail call <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %img, target("spirv.Sampler") %0, <2 x float> <float 1.000000e+00, float 2.000000e+00>)
  ret void
}

define spir_kernel void @foo(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %img) !clspv.pod_args_impl !0 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 1, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) zeroinitializer)
  call void @bar(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %0)
  ret void
}

declare target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32, i32, i32, target("spirv.Sampler"))

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

!0 = !{i32 2}

