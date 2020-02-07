; RUN: clspv-opt -SpecializeImageTypesPass %s -o %t
; RUN: FileCheck %s < %t

; CHECK: %[[IMAGE:opencl.image1d_ro_t.uint.sampled]] = type opaque
; CHECK: declare spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi.[[IMAGE]](%[[IMAGE]] addrspace(1)*, i32) [[ATTRS:#[0-9]+]]
; CHECK: define spir_kernel void @read_uint
; CHECK: call spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi.[[IMAGE]](%[[IMAGE]] addrspace(1)* %image
; CHECK: attributes [[ATTRS]] = { convergent nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_uint(%opencl.image1d_ro_t addrspace(1)* %image, i32 %coord, <4 x i32> addrspace(1)* nocapture %data) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)* %image, i32 %coord) #3
  store <4 x i32> %call, <4 x i32> addrspace(1)* %data, align 16
  ret void
}

declare spir_func <4 x i32> @_Z12read_imageui14ocl_image1d_roi(%opencl.image1d_ro_t addrspace(1)*, i32) local_unnamed_addr #1

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

