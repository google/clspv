; RUN: clspv-opt -SpecializeImageTypesPass %s -o %t
; RUN: FileCheck %s < %t

; CHECK-DAG: %[[RO_IM:opencl.image2d_ro_t.float.sampled]] = type opaque
; CHECK-DAG: %[[WO_IM:opencl.image2d_wo_t.int]] = type opaque
; CHECK-DAG: declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f.[[RO_IM]](%[[RO_IM]] addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x float>)
; CHECK-DAG: declare spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i.[[WO_IM]](%[[WO_IM]] addrspace(1)*, <2 x i32>, <4 x i32>)
; CHECK: define spir_func void @foo
; CHECK: call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f.[[RO_IM]](%[[RO_IM]] addrspace(1)* %ro
; CHECK: call spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i.[[WO_IM]](%[[WO_IM]] addrspace(1)* %wo
; CHECK: define spir_kernel void @read_float
; CHECK: call spir_func void @foo(%[[RO_IM]] addrspace(1)* %ro, %[[WO_IM]] addrspace(1)* %wo

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t = type opaque
%opencl.image2d_wo_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float(%opencl.image2d_ro_t addrspace(1)* %ro, %opencl.image2d_wo_t addrspace(1)* %wo, <2 x float> %coord) local_unnamed_addr {
entry:
  tail call spir_func void @foo(%opencl.image2d_ro_t addrspace(1)* %ro, %opencl.image2d_wo_t addrspace(1)* %wo, <2 x float> %coord)
  ret void
}

define spir_func void @foo(%opencl.image2d_ro_t addrspace(1)* %ro, %opencl.image2d_wo_t addrspace(1)* %wo, <2 x float> %coord) {
entry:
  %0 = tail call %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32 23)
  %call = tail call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)* %ro, %opencl.sampler_t addrspace(2)* %0, <2 x float> %coord)
  %c_cast = bitcast <2 x float> %coord to <2 x i32>
  %i_cast = bitcast <4 x float> %call to <4 x i32>
  tail call spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i(%opencl.image2d_wo_t addrspace(1)* %wo, <2 x i32> %c_cast, <4 x i32> %i_cast)
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(%opencl.image2d_ro_t addrspace(1)*, %opencl.sampler_t addrspace(2)*, <2 x float>) local_unnamed_addr

declare spir_func void @_Z12write_imagei14ocl_image2d_woDv2_iDv4_i(%opencl.image2d_wo_t addrspace(1)*, <2 x i32>, <4 x i32>) local_unnamed_addr #1

declare %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32) local_unnamed_addr

