; RUN: clspv-opt %s -o %t.ll -opaque-pointers --passes=specialize-image-types --cl-std=CL2.0
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func <4 x i32> @_Z11read_imagei26ocl_image1d_ro.int.sampled11ocl_samplerf(ptr addrspace(1) %t_in1,
; CHECK: call spir_func <4 x i32> @_Z11read_imagei18ocl_image1d_rw.inti(ptr addrspace(1) %t_in2,
; CHECK: call spir_func void @_Z12write_imagei18ocl_image1d_rw.intiDv4_i(ptr addrspace(1) %t_out,

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) %t_in1, ptr addrspace(1) %t_in2, ptr addrspace(1) %t_out, ptr addrspace(2) %s, float %m, i32 %n) !clspv.pod_args_impl !7 {
entry:
  %call = call spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_samplerf(ptr addrspace(1) %t_in1, ptr addrspace(2) %s, float %m)
  %call1 = call spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_rwi(ptr addrspace(1) %t_in2, i32 %n)
  %add = add <4 x i32> %call, %call1
  call spir_func void @_Z12write_imagei14ocl_image1d_woiDv4_i(ptr addrspace(1) %t_out, i32 %n, <4 x i32> %add)
  ret void
}

declare spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_ro11ocl_samplerf(ptr addrspace(1), ptr addrspace(2), float)
declare spir_func <4 x i32> @_Z11read_imagei14ocl_image1d_rwi(ptr addrspace(1), i32)
declare spir_func void @_Z12write_imagei14ocl_image1d_woiDv4_i(ptr addrspace(1), i32, <4 x i32>)

!7 = !{i32 2}

