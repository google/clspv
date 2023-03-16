; RUN: clspv-opt %s -o %t.ll --passes=specialize-image-types
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; CHECK-DAG: [[image1df:target\(\"spirv.Image\", float, 0, 0, 0, 0, 1, 0, 0, 0\)]]
; CHECK-DAG: [[image2di:target\(\"spirv.Image\", i32, 1, 0, 0, 0, 2, 0, 1, 0\)]]
; CHECK-DAG: [[image3du:target\(\"spirv.Image\", i32, 2, 0, 0, 0, 1, 0, 0, 1\)]]
; CHECK-DAG: [[image1dbufferf:target\(\"spirv.Image\", float, 5, 0, 0, 0, 2, 0, 1, 0\)]]
; CHECK-DAG: [[image2darrayi:target\(\"spirv.Image\", i32, 1, 0, 1, 0, 1, 0, 0, 0\)]]

; CHECK-LABEL: @test1
; CHECK: [[image1df]] %f_im
; CHECK: @{{[a-zA-Z0-9_]+}}read_imagef{{[a-zA-Z0-9_.]+}}([[image1df]] %f_im
define dso_local spir_kernel void @test1(target("spirv.Sampler") %s, target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) %f_im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) %f_im, target("spirv.Sampler") %s, float 0.000000e+00)
  store <4 x float> %call, ptr addrspace(1) %out, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), float)

; CHECK-LABEL: @test2
; CHECK: [[image2di]] %i_im
; CHECK: @{{[a-zA-Z0-9_]+}}write_imagei{{[a-zA-Z0-9_.]+}}([[image2di]] %i_im
define dso_local spir_kernel void @test2(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %i_im, ptr addrspace(1) nocapture readonly align 16 %data) !clspv.pod_args_impl !10 {
entry:
  %0 = load <4 x i32>, ptr addrspace(1) %data, align 16
  tail call spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %i_im, <2 x i32> zeroinitializer, <4 x i32> %0)
  ret void
}

declare spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, <4 x i32>)

; CHECK-LABEL: @test3
; CHECK: [[image3du]] %u_im
; CHECK: @{{[a-zA-Z0-9_]+}}read_imageui{{[a-zA-Z0-9_.]+}}([[image3du]] %u_im
define dso_local spir_kernel void @test3(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %u_im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %call = tail call spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_roDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %u_im, <4 x i32> zeroinitializer)
  store <4 x i32> %call, ptr addrspace(1) %out, align 16
  ret void
}

declare spir_func <4 x i32> @_Z12read_imageui14ocl_image3d_roDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), <4 x i32>)

; CHECK-LABEL: @test4
; CHECK: [[image1dbufferf]] %im
; CHECK: @{{[a-zA-Z0-9_]+}}write_imagef{{[a-zA-Z0-9_.]+}}([[image1dbufferf]] %im
define dso_local spir_kernel void @test4(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 1) %im, ptr addrspace(1) nocapture readonly align 16 %data) !clspv.pod_args_impl !10 {
entry:
  %0 = load <4 x float>, ptr addrspace(1) %data, align 16
  tail call spir_func void @_Z12write_imagef21ocl_image1d_buffer_woiDv4_f(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 1) %im, i32 0, <4 x float> %0)
  ret void
}

declare spir_func void @_Z12write_imagef21ocl_image1d_buffer_woiDv4_f(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 1), i32, <4 x float>)

; CHECK-LABEL: @test5
; CHECK: [[image2darrayi]] %im
; CHECK: @{{[a-zA-Z0-9_]+}}read_imagei{{[a-zA-Z0-9_.]+}}([[image2darrayi]] %im
define dso_local spir_kernel void @test5(target("spirv.Image", void, 1, 0, 1, 0, 0, 0, 0) %im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %0 = tail call spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32 18)
  %1 = tail call <4 x i32> @_Z11read_imagei20ocl_image2d_array_ro11ocl_samplerDv4_f(target("spirv.Image", void, 1, 0, 1, 0, 0, 0, 0) %im, target("spirv.Sampler") %0, <4 x float> zeroinitializer)
  store <4 x i32> %1, ptr addrspace(1) %out, align 16
  ret void
}

declare spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32)

declare <4 x i32> @_Z11read_imagei20ocl_image2d_array_ro11ocl_samplerDv4_f(target("spirv.Image", void, 1, 0, 1, 0, 0, 0, 0), target("spirv.Sampler"), <4 x float>)

!10 = !{i32 2}
