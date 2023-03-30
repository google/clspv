; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK: declare spir_func <4 x float> @_Z11read_imagef{{.*}}([[image:target\(\"spirv.Image\", float, 1, 0, 0, 0, 1, 0, 0, 0\)]], target("spirv.Sampler"), <2 x float>)
; CHECK: define spir_kernel void @read_float1
; CHECK: call spir_func <4 x float> @bar([[image]] %image, <2 x float> %coord
; CHECK: define spir_kernel void @read_float2
; CHECK: call spir_func <4 x float> @bar([[image]] %image, <2 x float> %coord
; CHECK: define spir_func <4 x float> @bar([[image]] %image, <2 x float> %coord
; CHECK: call spir_func <4 x float> @_Z11read_imagef{{.*}}([[image]] %image

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float1(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, <2 x float> %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr {
entry:
  %call = tail call spir_func <4 x float> @bar(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, <2 x float> %coord)
  store <4 x float> %call, ptr addrspace(1) %data, align 16
  ret void
}

define spir_kernel void @read_float2(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, <2 x float> %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr {
entry:
  %call = tail call spir_func <4 x float> @bar(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, <2 x float> %coord)
  store <4 x float> %call, ptr addrspace(1) %data, align 16
  ret void
}

define spir_func <4 x float> @bar(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, <2 x float> %coord) {
  %sampler = tail call target("spirv.Sampler") @__translate_sampler_initializer(i32 23)
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %image, target("spirv.Sampler") %sampler, <2 x float> %coord)
  ret <4 x float> %call
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), <2 x float>) local_unnamed_addr

declare target("spirv.Sampler") @__translate_sampler_initializer(i32) local_unnamed_addr

