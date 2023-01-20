; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK: define spir_kernel void @read_float
; CHECK: call spir_func <4 x float> @_Z11read_imagef34[[IMAGE:ocl_image1d_array_ro.float.sampled]]11ocl_samplerDv2_f(ptr addrspace(1) %image
; CHECK: call spir_func i32 @_Z15get_image_width34[[IMAGE]](ptr addrspace(1) %image
; CHECK-DAG: declare spir_func <4 x float> @_Z11read_imagef34[[IMAGE]]11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>) [[ATTRS1:#[0-9]+]]
; CHECK-DAG: declare spir_func i32 @_Z15get_image_width34[[IMAGE]](ptr addrspace(1)) [[ATTRS2:#[0-9]+]]
; CHECK-DAG: attributes [[ATTRS1]] = { convergent nounwind }
; CHECK-DAG: attributes [[ATTRS2]] = { nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_array_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float(ptr addrspace(1) %image, <2 x float> %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr #0 {
entry:
  %0 = tail call ptr addrspace(2) @__translate_sampler_initializer(i32 23) #2
  %call = tail call spir_func <4 x float> @_Z11read_imagef20ocl_image1d_array_ro11ocl_samplerDv2_f(ptr addrspace(1) %image, ptr addrspace(2) %0, <2 x float> %coord) #3
  %w = tail call spir_func i32 @_Z15get_image_width20ocl_image1d_array_ro(ptr addrspace(1) %image)
  store <4 x float> %call, <4 x float> addrspace(1)* %data, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef20ocl_image1d_array_ro11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>) local_unnamed_addr #1

declare spir_func i32 @_Z15get_image_width20ocl_image1d_array_ro(ptr addrspace(1)) #2

declare ptr addrspace(2) @__translate_sampler_initializer(i32) local_unnamed_addr

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

