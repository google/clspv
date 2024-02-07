; RUN: clspv-opt -constant-args-ubo %s -o %t.ll -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,i,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,ro_image
; MAP-NEXT: kernel,foo,arg,s,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,sampler
; MAP-NEXT: kernel,foo,arg,offset,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,buffer_ubo
; MAP-NEXT: kernel,foo,arg,c,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,pod_ubo,argSize,8
; MAP-NEXT: kernel,foo,arg,data,argOrdinal,4,descriptorSet,0,binding,4,offset,0,argKind,buffer

; CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: OpDecorate [[image_var:%[0-9a-zA-Z_]+]] Binding 0
; CHECK-DAG: OpDecorate [[image_var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[sampler_var:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[sampler_var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[offset_var:%[0-9a-zA-Z_]+]] Binding 2
; CHECK-DAG: OpDecorate [[offset_var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[offset_var]] NonWritable
; CHECK-DAG: OpDecorate [[c_var:%[0-9a-zA-Z_]+]] Binding 3
; CHECK-DAG: OpDecorate [[c_var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[data_var:%[0-9a-zA-Z_]+]] Binding 4
; CHECK-DAG: OpDecorate [[data_var]] DescriptorSet 0
; CHECK-NOT: OpExtension
; CHECK-DAG: [[float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
; CHECK-DAG: [[image:%[0-9a-zA-Z_]+]] = OpTypeImage [[float]] 2D 0 0 0 1 Unknown
; CHECK-DAG: [[sampled_image:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[image]]
; CHECK-DAG: [[image_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[image]]
; CHECK-DAG: [[sampler:%[0-9a-zA-Z_]+]] = OpTypeSampler
; CHECK-DAG: [[sampler_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[sampler]]
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 4
; CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
; CHECK-DAG: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[v4float]] [[int_4096]]
; CHECK-DAG: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
; CHECK-DAG: [[offset_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
; CHECK-DAG: [[v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 2
; CHECK-DAG: [[struct_v2float:%[0-9a-zA-Z_]+]] = OpTypeStruct [[v2float]]
; CHECK-DAG: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct_v2float]]
; CHECK-DAG: [[runtime]] = OpTypeRuntimeArray [[v4float]]
; CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
; CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
; CHECK-DAG: [[ptr_uniform_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[v4float]]
; CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
; CHECK-DAG: [[ptr_uniform_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[v2float]]
; CHECK-DAG: [[ptr_storagebuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[v4float]]
; CHECK-DAG: [[float_zero:%[0-9a-zA-Z_]+]] = OpConstant [[float]] 0
; CHECK: [[image_var]] = OpVariable [[image_ptr]] UniformConstant
; CHECK: [[sampler_var]] = OpVariable [[sampler_ptr]] UniformConstant
; CHECK: [[offset_var]] = OpVariable [[offset_ptr]] Uniform
; CHECK: [[c_var]] = OpVariable [[c_ptr]] Uniform
; CHECK: [[data_var]] = OpVariable [[data_ptr]] StorageBuffer
; CHECK: [[load_image:%[0-9a-zA-Z_]+]] = OpLoad [[image]] [[image_var]]
; CHECK: [[load_sampler:%[0-9a-zA-Z_]+]] = OpLoad [[sampler]] [[sampler_var]]
; CHECK: [[offset_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_uniform_v4float]] [[offset_var]] [[zero]] [[zero]]
; CHECK: [[c_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_uniform_v2float]] [[c_var]] [[zero]]
; CHECK: [[load_c:%[0-9a-zA-Z_]+]] = OpLoad [[v2float]] [[c_gep]]
; CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_storagebuffer_v4float]] [[data_var]] [[zero]] [[zero]]
; CHECK: [[sampled:%[0-9a-zA-Z_]+]] = OpSampledImage [[sampled_image]] [[load_image]] [[load_sampler]]
; CHECK: [[sample:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[v4float]] [[sampled]] [[load_c]] Lod [[float_zero]]
; CHECK: [[offset_load:%[0-9a-zA-Z_]+]] = OpLoad [[v4float]] [[offset_gep]]
; CHECK: [[add:%[0-9a-zA-Z_]+]] = OpFAdd [[v4float]] [[sample]] [[offset_load]]
; CHECK: OpStore [[data_gep]] [[add]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define spir_kernel void @foo(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %i, target("spirv.Sampler") %s, ptr addrspace(2) nocapture readonly align 16 %offset, <2 x float> %c, ptr addrspace(1) nocapture writeonly align 16 %data) !clspv.pod_args_impl !8 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) undef)
  %1 = call target("spirv.Sampler") @_Z14clspv.resource.1(i32 0, i32 1, i32 8, i32 1, i32 1, i32 0, target("spirv.Sampler") zeroinitializer)
  %2 = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 1, i32 2, i32 2, i32 0, { [4096 x <4 x float>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x float>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(6) @_Z14clspv.resource.3(i32 0, i32 3, i32 4, i32 3, i32 3, i32 0, { <2 x float> } zeroinitializer)
  %5 = getelementptr { <2 x float> }, ptr addrspace(6) %4, i32 0, i32 0
  %6 = load <2 x float>, ptr addrspace(6) %5, align 8
  %7 = call ptr addrspace(1) @_Z14clspv.resource.4(i32 0, i32 4, i32 0, i32 4, i32 4, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %8 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %7, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %1, <2 x float> %6)
  %9 = load <4 x float>, ptr addrspace(2) %3, align 16
  %add = fadd <4 x float> %call, %9
  store <4 x float> %add, ptr addrspace(1) %8, align 16
  ret void
}

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

declare target("spirv.Sampler") @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Sampler"))

declare ptr addrspace(2) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [4096 x <4 x float>] })

declare ptr addrspace(6) @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { <2 x float> })

declare ptr addrspace(1) @_Z14clspv.resource.4(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

!8 = !{i32 1}

