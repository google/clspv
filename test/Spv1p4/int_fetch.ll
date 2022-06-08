; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpImageFetch %{{.*}} %{{.*}} %{{.*}} Lod|SignExtend

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t.int.sampled = type opaque

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func <4 x i32> @_Z11read_imagei31opencl.image2d_ro_t.int.sampledDv2_i(%opencl.image2d_ro_t.int.sampled addrspace(1)*, <2 x i32>)

define spir_kernel void @foo(<4 x i32> addrspace(1)* nocapture %out, %opencl.image2d_ro_t.int.sampled addrspace(1)* %i)!clspv.pod_args_impl !10 {
entry:
  %0 = call { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, { [0 x <4 x i32>] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call %opencl.image2d_ro_t.int.sampled addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, %opencl.image2d_ro_t.int.sampled zeroinitializer)
  %call = tail call spir_func <4 x i32> @_Z11read_imagei31opencl.image2d_ro_t.int.sampledDv2_i(%opencl.image2d_ro_t.int.sampled addrspace(1)* %2, <2 x i32> zeroinitializer)
  store <4 x i32> %call, <4 x i32> addrspace(1)* %1, align 16
  ret void
}

declare { [0 x <4 x i32>] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare %opencl.image2d_ro_t.int.sampled addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, %opencl.image2d_ro_t.int.sampled)

!10 = !{i32 2}


