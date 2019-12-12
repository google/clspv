; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

; CHECK: [[sampler:%opencl.sampler_t]] = type opaque

; CHECK: @readf(
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC:@__translate_sampler_initializer]](i32 16)
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],

; CHECK: @readui(
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image1d_ro11ocl_samplerf({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],

; CHECK: @readi(
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_samplerf({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],
; CHECK: [[trans:%[a-zA-Z0-9_]+]] = call [[sampler]] addrspace(2)* [[FUNC]](i32 16)
; CHECK: call <4 x i32> @_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_f({{.*}}, [[sampler]] addrspace(2)* [[trans]],

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_ro_t = type opaque
%opencl.image2d_ro_t = type opaque
%opencl.image3d_ro_t = type opaque

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer
; Function Attrs: convergent nounwind
define spir_kernel void @readf(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d, <4 x float> addrspace(1)* %out) !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)* %im1d, i32 0)
  %call1 = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, <2 x i32> zeroinitializer)
  %call3 = call spir_func <4 x float> @_Z11read_imagef14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> zeroinitializer)
  ret void
}
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)*, i32)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)*, <2 x i32>)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x float> @_Z11read_imagef14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)*, <4 x i32>)
; Function Attrs: convergent nounwind
define spir_kernel void @readui(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> addrspace(1)* %out) !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !8 !kernel_arg_base_type !9 !kernel_arg_type_qual !7 {
entry:
  %call = call spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)* %im1d, i32 0)
  %call1 = call spir_func <4 x i32> @_Z12read_imageui14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, <2 x i32> zeroinitializer)
  %call3 = call spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> zeroinitializer)
  ret void
}
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)*, i32)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)*, <2 x i32>)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)*, <4 x i32>)
; Function Attrs: convergent nounwind
define spir_kernel void @readi(%opencl.image1d_ro_t addrspace(1)* %im1d, %opencl.image2d_ro_t addrspace(1)* %im2d, %opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> addrspace(1)* %out) !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !10 !kernel_arg_base_type !11 !kernel_arg_type_qual !7 {
entry:
  %call = call spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)* %im1d, i32 0)
  %call1 = call spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)* %im2d, <2 x i32> zeroinitializer)
  %call3 = call spir_func <4 x i32> @_Z11read_imagei14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)* %im3d, <4 x i32> zeroinitializer)
  ret void
}
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)*, i32)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_roDv2_i(%opencl.image2d_ro_t addrspace(1)*, <2 x i32>)
; Function Attrs: convergent nounwind readonly
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image3d_roDv4_i(%opencl.image3d_ro_t addrspace(1)*, <4 x i32>)

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 10.0.0 (https://github.com/llvm/llvm-project abe8de29c4ae5eca86f3594d2edd43b2fcbda623)"}
!3 = !{i32 1, i32 1, i32 1, i32 1}
!4 = !{!"read_only", !"read_only", !"read_only", !"none"}
!5 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"float4*"}
!6 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"float __attribute__((ext_vector_type(4)))*"}
!7 = !{!"", !"", !"", !""}
!8 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"uint4*"}
!9 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"uint __attribute__((ext_vector_type(4)))*"}
!10 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"int4*"}
!11 = !{!"image1d_t", !"image2d_t", !"image3d_t", !"int __attribute__((ext_vector_type(4)))*"}


