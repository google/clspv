; RUN: clspv-opt %s -o %t.ll --passes="allocate-descriptors"
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; CHECK-DAG: [[sampler:target\(\"spirv.Sampler\"\)]]
; CHECK-DAG: [[image1df:target\(\"spirv.Image\", float, 0, 0, 0, 0, 1, 0, 0, 0\)]]
; CHECK-DAG: [[image2di:target\(\"spirv.Image\", i32, 1, 0, 0, 0, 2, 0, 1, 0\)]]
; CHECK-DAG: [[image3du:target\(\"spirv.Image\", i32, 2, 0, 0, 0, 1, 0, 0, 1\)]]
; CHECK-DAG: [[image1dbufferf:target\(\"spirv.Image\", float, 5, 0, 0, 0, 2, 0, 1, 0\)]]
; CHECK-DAG: [[image2darrayi:target\(\"spirv.Image\", i32, 1, 0, 1, 0, 1, 0, 0, 0\)]]

declare spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32)
declare spir_func <4 x float> @_Z11read_imagef30ocl_image1d_ro_t.float.sampled11ocl_samplerf(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), float)
declare spir_func void @_Z12write_imagei20ocl_image2d_wo_t.intDv2_iDv4_i(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0), <2 x i32>, <4 x i32>)
declare spir_func <4 x i32> @_Z12read_imageui29ocl_image3d_ro_t.uint.sampledDv4_i(target("spirv.Image", i32, 2, 0, 0, 0, 1, 0, 0, 1), <4 x i32>)
declare spir_func void @_Z12write_imagef29ocl_image1d_buffer_wo_t.floatiDv4_f(target("spirv.Image", float, 5, 0, 0, 0, 2, 0, 1, 0), i32, <4 x float>)
declare <4 x i32> @_Z11read_imagei34ocl_image2d_array_ro_t.int.sampled11ocl_samplerDv4_f(target("spirv.Image", i32, 1, 0, 1, 0, 1, 0, 0, 0), target("spirv.Sampler"), <4 x float>)

; CHECK-LABEL: @test1
; CHECK: call [[sampler]] @_Z14clspv.resource.0(i32 1, i32 0, i32 8, i32 0, i32 0, i32 0, [[sampler]]
; CHECK: call [[image1df]] @_Z14clspv.resource.1(i32 1, i32 1, i32 6, i32 1, i32 1, i32 0, [[image1df]]
define spir_kernel void @test1(target("spirv.Sampler") %s, target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %f_im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef30ocl_image1d_ro_t.float.sampled11ocl_samplerf(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %f_im, target("spirv.Sampler") %s, float 0.000000e+00)
  store <4 x float> %call, ptr addrspace(1) %out, align 16
  ret void
}

; CHECK-LABEL: @test2
; CHECK: call [[image2di]] @_Z14clspv.resource.3(i32 1, i32 0, i32 7, i32 0, i32 3, i32 0, [[image2di]]
define spir_kernel void @test2(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) %i_im, ptr addrspace(1) nocapture readonly align 16 %data) !clspv.pod_args_impl !10 {
entry:
  %0 = load <4 x i32>, ptr addrspace(1) %data, align 16
  tail call spir_func void @_Z12write_imagei20ocl_image2d_wo_t.intDv2_iDv4_i(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) %i_im, <2 x i32> zeroinitializer, <4 x i32> %0)
  ret void
}

; CHECK-LABEL: @test3
; CHECK: call [[image3du]] @_Z14clspv.resource.5(i32 1, i32 0, i32 6, i32 0, i32 5, i32 0, [[image3du]]
define spir_kernel void @test3(target("spirv.Image", i32, 2, 0, 0, 0, 1, 0, 0, 1) %u_im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %call = tail call spir_func <4 x i32> @_Z12read_imageui29ocl_image3d_ro_t.uint.sampledDv4_i(target("spirv.Image", i32, 2, 0, 0, 0, 1, 0, 0, 1) %u_im, <4 x i32> zeroinitializer)
  store <4 x i32> %call, ptr addrspace(1) %out, align 16
  ret void
}

; CHECK-LABEL: @test4
; CHECK: call [[image1dbufferf]] @_Z14clspv.resource.6(i32 1, i32 0, i32 11, i32 0, i32 6, i32 0, [[image1dbufferf]]
define spir_kernel void @test4(target("spirv.Image", float, 5, 0, 0, 0, 2, 0, 1, 0) %im, ptr addrspace(1) nocapture readonly align 16 %data) !clspv.pod_args_impl !10 {
entry:
  %0 = load <4 x float>, ptr addrspace(1) %data, align 16
  tail call spir_func void @_Z12write_imagef29ocl_image1d_buffer_wo_t.floatiDv4_f(target("spirv.Image", float, 5, 0, 0, 0, 2, 0, 1, 0) %im, i32 0, <4 x float> %0)
  ret void
}

; CHECK-LABEL: @test5
; CHECK: call [[image2darrayi]] @_Z14clspv.resource.8(i32 1, i32 0, i32 6, i32 0, i32 8, i32 0, [[image2darrayi]]
; CHECK: call [[sampler]] @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 18, [[sampler]]
define spir_kernel void @test5(target("spirv.Image", i32, 1, 0, 1, 0, 1, 0, 0, 0) %im, ptr addrspace(1) nocapture writeonly align 16 %out) !clspv.pod_args_impl !10 {
entry:
  %0 = tail call spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32 18)
  %1 = tail call <4 x i32> @_Z11read_imagei34ocl_image2d_array_ro_t.int.sampled11ocl_samplerDv4_f(target("spirv.Image", i32, 1, 0, 1, 0, 1, 0, 0, 0) %im, target("spirv.Sampler") %0, <4 x float> zeroinitializer)
  store <4 x i32> %1, ptr addrspace(1) %out, align 16
  ret void
}


!10 = !{i32 2}

