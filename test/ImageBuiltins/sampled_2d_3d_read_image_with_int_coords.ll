; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

; CHECK: %0 = sitofp <2 x i32> <i32 3, i32 7> to <2 x float>
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x float> %0)
; CHECK: %2 = sitofp <2 x i32> <i32 3, i32 7> to <2 x float>
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x float> %2)
; CHECK: %4 = sitofp <2 x i32> <i32 3, i32 7> to <2 x float>
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x float> %4)
; CHECK: %6 = sitofp <4 x i32> <i32 3, i32 7, i32 5, i32 0> to <4 x float>
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x float> %6)
; CHECK: %8 = sitofp <4 x i32> <i32 3, i32 7, i32 5, i32 0> to <4 x float>
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x float> %8)
; CHECK: %10 = sitofp <4 x i32> <i32 3, i32 7, i32 5, i32 0> to <4 x float>
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_f(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x float> %10)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.sampler_t = type opaque
%opencl.image2d_ro_t = type opaque
%opencl.image3d_ro_t = type opaque

; Function Attrs: convergent nounwind
define spir_kernel void @test(%opencl.sampler_t addrspace(2)* %sampler, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x i32> <i32 3, i32 7>) #1
  %call2 = tail call spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x i32> <i32 3, i32 7>) #1
  %call4 = tail call spir_func <4 x i32> @_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.sampler_t addrspace(2)* %sampler, <2 x i32> <i32 3, i32 7>) #1
  %call6 = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x i32> <i32 3, i32 7, i32 5, i32 0>) #1
  %call8 = tail call spir_func <4 x i32> @_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x i32> <i32 3, i32 7, i32 5, i32 0>) #1
  %call10 = tail call spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, %opencl.sampler_t addrspace(2)* %sampler, <4 x i32> <i32 3, i32 7, i32 5, i32 0>) #1
  ret void
}

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x i32>) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x i32>) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_i(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x i32>) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <4 x i32>) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <4 x i32>) local_unnamed_addr #1

; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_i(%opencl.image3d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <4 x i32>) local_unnamed_addr #1

attributes #0 = { convergent nounwind }
attributes #1 = { convergent nounwind readonly }

