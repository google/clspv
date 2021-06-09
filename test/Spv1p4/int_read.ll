; RUN: clspv-opt -SPIRVProducerPass %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpImageRead %{{.*}} %{{.*}} SignExtend

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_rw_t.int = type opaque

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_rwDv2_i.opencl.image2d_rw_t.int(%opencl.image2d_rw_t.int addrspace(1)*, <2 x i32>)

define spir_kernel void @foo(<4 x i32> addrspace(1)* nocapture %out, %opencl.image2d_rw_t.int addrspace(1)* %i) !clspv.pod_args_impl !11 {
entry:
  %0 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0)
  %1 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call %opencl.image2d_rw_t.int addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 7, i32 1, i32 1, i32 0)
  %call = tail call spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_rwDv2_i.opencl.image2d_rw_t.int(%opencl.image2d_rw_t.int addrspace(1)* %2, <2 x i32> zeroinitializer)
  store <4 x i32> %call, <4 x i32> addrspace(1)* %1, align 16
  ret void
}

declare { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32)

declare %opencl.image2d_rw_t.int addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32)

!11 = !{i32 2}

