; RUN: clspv-opt %s -o %t.ll -opaque-pointers --passes=specialize-image-types
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func <4 x float> @_Z11read_imagef35ocl_image1d_buffer_ro.float.sampled11ocl_samplerf(ptr addrspace(1) %t_in1,
; CHECK: call spir_func <4 x float> @_Z11read_imagef35ocl_image1d_buffer_ro.float.sampledi(ptr addrspace(1) %t_in2,
; CHECK: call spir_func void @_Z12write_imagef27ocl_image1d_buffer_wo.floatiDv4_f(ptr addrspace(1) %t_out,

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) %t_in1, ptr addrspace(1) %t_in2, ptr addrspace(1) %t_out, float %m, i32 %n, ptr addrspace(2) %s) !clspv.pod_args_impl !7 {
entry:
  %call = call spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_ro11ocl_samplerf(ptr addrspace(1) %t_in1, ptr addrspace(2) %s, float %m)
  %call1 = call spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_roi(ptr addrspace(1) %t_in2, i32 %n)
  %add = fadd <4 x float> %call, %call1
  call spir_func void @_Z12write_imagef21ocl_image1d_buffer_woiDv4_f(ptr addrspace(1) %t_out, i32 %n, <4 x float> %add)
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_ro11ocl_samplerf(ptr addrspace(1), ptr addrspace(2), float)
declare spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_roi(ptr addrspace(1), i32)
declare spir_func void @_Z12write_imagef21ocl_image1d_buffer_woiDv4_f(ptr addrspace(1), i32, <4 x float>)

!7 = !{i32 2}

