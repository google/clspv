; RUN: clspv-opt %s -o %t.ll -opaque-pointers --passes=specialize-image-types
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampled11ocl_samplerDv2_f(ptr addrspace(1) %t_in1,
; CHECK: call spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampledDv2_i(ptr addrspace(1) %t_in2,
; CHECK: call spir_func void @_Z12write_imagef20ocl_image2d_wo.floatDv2_iDv4_f(ptr addrspace(1) %t_out,

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) %t_in1, ptr addrspace(1) %t_in2, ptr addrspace(1) %t_out, <2 x float> %m, <2 x i32> %n, ptr addrspace(2) %s) !clspv.pod_args_impl !7 {
entry:
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1) %t_in1, ptr addrspace(2) %s, <2 x float> %m)
  %call1 = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(ptr addrspace(1) %t_in2, <2 x i32> %n)
  %add = fadd <4 x float> %call, %call1
  call spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(ptr addrspace(1) %t_out, <2 x i32> %n, <4 x float> %add)
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>)
declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(ptr addrspace(1), <2 x i32>)
declare spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(ptr addrspace(1), <2 x i32>, <4 x float>)

!7 = !{i32 2}

