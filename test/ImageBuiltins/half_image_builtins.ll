; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_ro_t = type opaque
%opencl.image2d_ro_t = type opaque
%opencl.image3d_ro_t = type opaque
%opencl.sampler_t = type opaque
%opencl.image1d_wo_t = type opaque
%opencl.image2d_wo_t = type opaque
%opencl.image3d_wo_t = type opaque

; CHECK: @sampled_read
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %s
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
define spir_kernel void @sampled_read(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %s, <4 x half> addrspace(1)* %out)  {
entry:
  %call = call spir_func <4 x half> @_Z11read_imageh14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %s, float 0.000000e+00)
  %call1 = call spir_func <4 x half> @_Z11read_imageh14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %s, i32 0) 
  %call4 = call spir_func <4 x half> @_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %s, <2 x float> zeroinitializer) 
  %call7 = call spir_func <4 x half> @_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %s, <2 x i32> zeroinitializer) 
  %call10 = call spir_func <4 x half> @_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %s, <4 x float> zeroinitializer) 
  %call13 = call spir_func <4 x half> @_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %s, <4 x i32> zeroinitializer)
  ret void
}
declare spir_func <4 x half> @_Z11read_imageh14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, float) 
declare spir_func <4 x half> @_Z11read_imageh14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, i32) 
declare spir_func <4 x half> @_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x float>)
declare spir_func <4 x half> @_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x i32>)
declare spir_func <4 x half> @_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <4 x float>)
declare spir_func <4 x half> @_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <4 x i32>)

; CHECK: @unsampled_read
; CHECK: [[sampler:%[a-zA-Z0-9_]+]] = call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 16)
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = sitofp i32 0 to float
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* [[sampler]], float [[cast]])
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[sampler:%[a-zA-Z0-9_]+]] = call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 16)
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = sitofp <2 x i32> zeroinitializer to <2 x float>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* [[sampler]], <2 x float> [[cast]])
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
; CHECK: [[sampler:%[a-zA-Z0-9_]+]] = call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 16)
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = sitofp <4 x i32> zeroinitializer to <4 x float>
; CHECK: [[call:%[a-zA-Z0-9_]+]] = call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* [[sampler]], <4 x float> [[cast]])
; CHECK: fptrunc <4 x float> [[call]] to <4 x half>
define spir_kernel void @unsampled_read(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d, <4 x half> addrspace(1)* %out) {
entry:
  %call = call spir_func <4 x half> @_Z11read_imageh14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)* %im1d, i32 0)
  %call1 = call spir_func <4 x half> @_Z11read_imageh14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, <2 x i32> zeroinitializer)
  %call4 = call spir_func <4 x half> @_Z11read_imageh14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> zeroinitializer)
  ret void
}
declare spir_func <4 x half> @_Z11read_imageh14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)*, i32) 
declare spir_func <4 x half> @_Z11read_imageh14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)*, <2 x i32>)
declare spir_func <4 x half> @_Z11read_imageh14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)*, <4 x i32>)

; CHECK: @write
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = fpext <4 x half> %data to <4 x float>
; CHECK: call void @_Z12write_imagef14ocl_image1d_woiDv4_f(%opencl.image1d_wo_t addrspace(1)* %im1d, i32 0, <4 x float> [[cast]])
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = fpext <4 x half> %data to <4 x float>
; CHECK: call void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(%opencl.image2d_wo_t addrspace(1)* %im2d, <2 x i32> zeroinitializer, <4 x float> [[cast]])
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = fpext <4 x half> %data to <4 x float>
; CHECK: call void @_Z12write_imagef14ocl_image3d_woDv4_iDv4_f(%opencl.image3d_wo_t addrspace(1)* %im3d, <4 x i32> zeroinitializer, <4 x float> [[cast]])
define spir_kernel void @write(%opencl.image1d_wo_t addrspace(1)* %im1d, %opencl.image2d_wo_t addrspace(1)* %im2d, %opencl.image3d_wo_t addrspace(1)* %im3d, <4 x half> %data) {
entry:
  call spir_func void @_Z12write_imageh14ocl_image1d_woiDv4_Dh(%opencl.image1d_wo_t addrspace(1)* %im1d, i32 0, <4 x half> %data)
  call spir_func void @_Z12write_imageh14ocl_image2d_woDv2_iDv4_Dh(%opencl.image2d_wo_t addrspace(1)* %im2d, <2 x i32> zeroinitializer, <4 x half> %data)
  call spir_func void @_Z12write_imageh14ocl_image3d_woDv4_iDv4_Dh(%opencl.image3d_wo_t addrspace(1)* %im3d, <4 x i32> zeroinitializer, <4 x half> %data)
  ret void
}
declare spir_func void @_Z12write_imageh14ocl_image1d_woiDv4_Dh(%opencl.image1d_wo_t addrspace(1)*, i32, <4 x half>)
declare spir_func void @_Z12write_imageh14ocl_image2d_woDv2_iDv4_Dh(%opencl.image2d_wo_t addrspace(1)*, <2 x i32>, <4 x half>)
declare spir_func void @_Z12write_imageh14ocl_image3d_woDv4_iDv4_Dh(%opencl.image3d_wo_t addrspace(1)*, <4 x i32>, <4 x half>)

