; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-NOT: OpTypeImage
; CHECK: OpTypeImage [[float]] 2D 0 0 0 1 Unknown
; CHECK-NOT: OpTypeImage

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t.float.sampled = type opaque

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampledDv2_i(%opencl.image2d_ro_t.float.sampled addrspace(1)*, <2 x i32>)

define void @bar(%opencl.image2d_ro_t.float.sampled addrspace(1)* %img) {
entry:
  %0 = tail call <4 x float> @_Z11read_imagef33opencl.image2d_ro_t.float.sampledDv2_i(%opencl.image2d_ro_t.float.sampled addrspace(1)* %img, <2 x i32> zeroinitializer)
  ret void
}

define spir_kernel void @foo(%opencl.image2d_ro_t.float.sampled addrspace(1)* %img) !clspv.pod_args_impl !0 {
entry:
  %0 = call %opencl.image2d_ro_t.float.sampled addrspace(1)* @_Z14clspv.resource.0(i32 1, i32 0, i32 6, i32 0, i32 0, i32 0, %opencl.image2d_ro_t.float.sampled zeroinitializer)
  call void @bar(%opencl.image2d_ro_t.float.sampled addrspace(1)* %0)
  ret void
}

declare %opencl.image2d_ro_t.float.sampled addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, %opencl.image2d_ro_t.float.sampled)

!0 = !{i32 2}
