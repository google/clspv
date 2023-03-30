; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK: declare spir_func i32 @_Z16get_image_height{{.*}}([[image:target\(\"spirv.Image\", float, 2, 0, 0, 0, 1, 0, 0, 0\)]]) [[ATTRS:#[0-9]+]]
; CHECK: declare spir_func <4 x float> @_Z11read_imagef{{.*}}([[image]], target("spirv.Sampler"), <4 x float>) [[ATTRS:#[0-9]+]]
; CHECK: define spir_kernel void @read_float
; CHECK: call spir_func <4 x float> @_Z11read_imagef{{.*}}([[image]] %image
; CHECK: call spir_func i32 @_Z16get_image_height{{.*}}([[image]] %image)
; CHECK: attributes [[ATTRS]] = { convergent nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image3d_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %image, <4 x float> %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr #0 {
entry:
  %0 = tail call target("spirv.Sampler") @__translate_sampler_initializer(i32 23) #2
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %image, target("spirv.Sampler") %0, <4 x float> %coord) #3
  %h = tail call spir_func i32 @_Z16get_image_height14ocl_image3d_ro(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %image)
  store <4 x float> %call, ptr addrspace(1) %data, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), <4 x float>) local_unnamed_addr #1

declare target("spirv.Sampler") @__translate_sampler_initializer(i32) local_unnamed_addr

declare spir_func i32 @_Z16get_image_height14ocl_image3d_ro(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0)) #1

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

