; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK: %[[IMAGE:opencl.image2d_array_wo_t.int]] = type opaque
; CHECK: declare spir_func <2 x i32> @_Z13get_image_dim29[[IMAGE]](%[[IMAGE]] addrspace(1)*) [[ATTRS:#[0-9]+]]
; CHECK: declare spir_func void @_Z12write_imagei29[[IMAGE]]Dv4_iDv4_i(%[[IMAGE]] addrspace(1)*, <4 x i32>, <4 x i32>) [[ATTRS]]
; CHECK: define spir_kernel void @write_int
; CHECK: call spir_func void @_Z12write_imagei29[[IMAGE]]Dv4_iDv4_i(%[[IMAGE]] addrspace(1)* %image
; CHECK: call spir_func <2 x i32> @_Z13get_image_dim29[[IMAGE]](%[[IMAGE]] addrspace(1)* %image
; CHECK: attributes [[ATTRS]] = { convergent nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_array_wo_t = type opaque

define spir_kernel void @write_int(%opencl.image2d_array_wo_t addrspace(1)* %image, <4 x i32> %coord, <4 x i32> addrspace(1)* nocapture %data) local_unnamed_addr #0 {
entry:
  %ld = load <4 x i32>, <4 x i32> addrspace(1)* %data, align 16
  call spir_func void @_Z12write_imagei20ocl_image2d_array_woDv4_iS0_(%opencl.image2d_array_wo_t addrspace(1)* %image, <4 x i32> %coord, <4 x i32> %ld) #2
  %dim = tail call spir_func <2 x i32> @_Z13get_image_dim20ocl_image2d_array_wo(%opencl.image2d_array_wo_t addrspace(1)* %image)
  ret void
}

declare spir_func void @_Z12write_imagei20ocl_image2d_array_woDv4_iS0_(%opencl.image2d_array_wo_t addrspace(1)*, <4 x i32>, <4 x i32>) local_unnamed_addr #1

declare spir_func <2 x i32> @_Z13get_image_dim20ocl_image2d_array_wo(%opencl.image2d_array_wo_t addrspace(1)*) #1

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { convergent nobuiltin nounwind readonly }

