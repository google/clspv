; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpImageSampleExplicitLod %{{.*}} %{{.*}} %{{.*}} Lod|SignExtend

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare <4 x i32> @_Z11read_imagei31opencl.image2d_ro_t.int.sampled11ocl_samplerDv2_f(target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define spir_kernel void @foo(<4 x i32> addrspace(1)* nocapture %out, target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0) %i, target("spirv.Sampler") %s)!clspv.pod_args_impl !10 {
entry:
  %0 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0) zeroinitializer)
  %3 = call target("spirv.Sampler") @_Z14clspv.resource.2(i32 0, i32 2, i32 8, i32 2, i32 2, i32 0, target("spirv.Sampler") zeroinitializer)
  %4 = tail call <4 x i32> @_Z11read_imagei31opencl.image2d_ro_t.int.sampled11ocl_samplerDv2_f(target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0) %2, target("spirv.Sampler") %3, <2 x float> zeroinitializer)
  store <4 x i32> %4, <4 x i32> addrspace(1)* %1, align 16
  ret void
}

declare { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32> ] })

declare target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Image", i32, 1, 0, 0, 0, 1, 0, 0, 0))

declare target("spirv.Sampler") @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, target("spirv.Sampler"))

!10 = !{i32 2}


