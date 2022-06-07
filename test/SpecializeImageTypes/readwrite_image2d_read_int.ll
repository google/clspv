; RUN: clspv-opt --passes=specialize-image-types %s -o %t -cl-std=CL2.0
; RUN: FileCheck %s < %t

; CHECK: %[[IMAGE:opencl.image2d_rw_t.int]] = type opaque
; CHECK: declare spir_func <4 x i32> @_Z11read_imagei23[[IMAGE]]Dv2_i(%[[IMAGE]] addrspace(1)*, <2 x i32>) [[ATTRS:#[0-9]+]]
; CHECK: define spir_kernel void @read_int
; CHECK: call spir_func <4 x i32> @_Z11read_imagei23[[IMAGE]]Dv2_i(%[[IMAGE]] addrspace(1)* %image
; CHECK: attributes [[ATTRS]] = { convergent nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_rw_t = type opaque

define spir_kernel void @read_int(%opencl.image2d_rw_t addrspace(1)* %image, <2 x i32> %coord, <4 x i32> addrspace(1)* nocapture %data) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_rwDv2_i(%opencl.image2d_rw_t addrspace(1)* %image, <2 x i32> %coord) #3
  store <4 x i32> %call, <4 x i32> addrspace(1)* %data, align 16
  ret void
}

declare spir_func <4 x i32> @_Z11read_imagei14ocl_image2d_rwDv2_i(%opencl.image2d_rw_t addrspace(1)*, <2 x i32>) local_unnamed_addr #1

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

