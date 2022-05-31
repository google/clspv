; RUN: clspv-opt -opaque-pointers %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(2) @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 21, %opencl.sampler_t zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) %t, <2 x float> %coords, ptr addrspace(1) align 16 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call spir_func ptr addrspace(2) @__translate_sampler_initializer(i32 21)
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1) %t, ptr addrspace(2) %0, <2 x float> %coords)
  store <4 x float> %call, ptr addrspace(1) %out, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>)

declare spir_func ptr addrspace(2) @__translate_sampler_initializer(i32)

!8 = !{i32 1}

