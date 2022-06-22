; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[float4:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 4
; CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
; CHECK-DAG: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 0 0 1
; CHECK-DAG: [[sampled_image:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[image]]
; CHECK-DAG: [[image_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[image]]
; CHECK-DAG: [[sampler_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[sampler]]
; CHECK-DAG: [[image_var:%[a-zA-Z0-9_]+]] = OpVariable [[image_ptr]] UniformConstant
; CHECK-DAG: [[sampler_var:%[a-zA-Z0-9_]+]] = OpVariable [[sampler_ptr]] UniformConstant
; CHECK-DAG: [[ld_image:%[a-zA-Z0-9_]+]] = OpLoad [[image]] [[image_var]]
; CHECK-DAG: [[ld_sampler:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]] [[sampler_var]]
; CHECK: [[combined:%[a-zA-Z0-9_]+]] = OpSampledImage [[sampled_image]] [[ld_image]] [[ld_sampler]]
; CHECK: OpImageSampleExplicitLod [[float4]] [[combined]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%ocl_image2d_ro.float.sampled = type opaque
%ocl_sampler = type opaque

define dso_local spir_kernel void @test(ptr addrspace(1) %t, ptr addrspace(2) %s, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, %ocl_image2d_ro.float.sampled zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 8, i32 1, i32 1, i32 0, %ocl_sampler zeroinitializer)
  %2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %3 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampled11ocl_samplerDv2_f(ptr addrspace(1) %0, ptr addrspace(2) %1, <2 x float> zeroinitializer)
  store <4 x float> %call, ptr addrspace(1) %3, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampled11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>)
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, %ocl_image2d_ro.float.sampled)
declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, %ocl_sampler)
declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

!10 = !{i32 2}

