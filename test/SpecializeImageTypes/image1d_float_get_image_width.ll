; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK-DAG: declare spir_func void @_Z12write_imagef{{.*}}([[image:target\(\"spirv.Image\", float, 0, 0, 0, 0, 2, 0, 1, 0\)]], i32, <4 x float>) [[ATTRS1:#[0-9]+]]
; CHECK-DAG: declare spir_func i32 @_Z15get_image_width{{.*}}([[image]]) [[ATTRS2:#[0-9]+]]
; CHECK: define spir_kernel void @write_float
; CHECK: call spir_func void @_Z12write_imagef{{.*}}([[image]] %image
; CHECK: call spir_func i32 @_Z15get_image_width{{.*}}([[image]] %image)
; CHECK-DAG: attributes [[ATTRS1]] = { convergent nounwind }
; CHECK-DAG: attributes [[ATTRS2]] = { convergent nobuiltin nounwind memory(read) }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_wo_t = type opaque

define spir_kernel void @write_float(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) %image, i32 %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr #0 {
entry:
  %ld = load <4 x float>, ptr addrspace(1) %data, align 16
  call spir_func void @_Z12write_imagef14ocl_image1d_woiDv4_f(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) %image, i32 %coord, <4 x float> %ld) #2
  %h = tail call spir_func i32 @_Z15get_image_width14ocl_image1d_wo(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1) %image)
  ret void
}

declare spir_func void @_Z12write_imagef14ocl_image1d_woiDv4_f(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1), i32, <4 x float>) local_unnamed_addr #1

declare spir_func i32 @_Z15get_image_width14ocl_image1d_wo(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 1)) #2

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { convergent nobuiltin nounwind readonly }

