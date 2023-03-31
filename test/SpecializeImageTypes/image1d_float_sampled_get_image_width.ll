; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK-DAG: declare spir_func <4 x float> @_Z11read_imagef{{.*}}([[image:target\(\"spirv.Image\", float, 0, 0, 0, 0, 1, 0, 0, 0, 0\)]], target("spirv.Sampler"), float) [[ATTRS1:#[0-9]+]]
; CHECK-DAG: declare spir_func i32 @_Z15get_image_width{{.*}}([[image]]) [[ATTRS2:#[0-9]+]]
; CHECK: define spir_kernel void @read_float
; CHECK: call spir_func <4 x float> @_Z11read_imagef{{.*}}([[image]] %image
; CHECK: call spir_func i32 @_Z15get_image_width{{.*}}([[image]] %image
; CHECK-DAG: attributes [[ATTRS1]] = { convergent nounwind }
; CHECK-DAG: attributes [[ATTRS2]] = { nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %image, float %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr #0 {
entry:
  %0 = tail call target("spirv.Sampler") @__translate_sampler_initializer(i32 23) #2
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %image, target("spirv.Sampler") %0, float %coord) #3
  %w = tail call spir_func i32 @_Z15get_image_width14ocl_image1d_ro(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %image)
  store <4 x float> %call, ptr addrspace(1) %data, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), float) local_unnamed_addr #1

declare spir_func i32 @_Z15get_image_width14ocl_image1d_ro(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0)) #2

declare target("spirv.Sampler") @__translate_sampler_initializer(i32) local_unnamed_addr

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

