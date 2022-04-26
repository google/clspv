; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

; CHECK: %0 = sitofp i32 3 to float
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, float %0)
; CHECK: %2 = sitofp i32 3 to float
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, float %2)
; CHECK: %4 = sitofp i32 3 to float
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image1d_ro11ocl_samplerf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, float %4)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.sampler_t = type opaque
%opencl.image1d_ro_t = type opaque

define spir_kernel void @test(%opencl.sampler_t addrspace(2)* %sampler, %opencl.image1d_ro_t addrspace(1)* %im1d) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, i32 3) #1
  %call2 = tail call spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, i32 3) #1
  %call4 = tail call spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.sampler_t addrspace(2)* %sampler, i32 3) #1
  ret void
}

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, i32) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, i32) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_ro11ocl_sampleri(%opencl.image1d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, i32) local_unnamed_addr #1

attributes #0 = { convergent nounwind }
attributes #1 = { convergent nounwind readonly }
