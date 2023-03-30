; RUN: clspv-opt --passes=specialize-image-types %s -o %t
; RUN: FileCheck %s < %t

; CHECK: declare spir_func <4 x float> @_Z11read_imagef{{.*}}([[image:target\(\"spirv.Image\", float, 0, 0, 1, 0, 1, 0, 0, 0\)]], <2 x i32>) [[ATTRS:#[0-9]+]]
; CHECK: define spir_kernel void @read_float
; CHECK: call spir_func <4 x float> @_Z11read_imagef{{.*}}([[image]] %image
; CHECK: attributes [[ATTRS]] = { convergent nounwind }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_array_ro_t = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @read_float(target("spirv.Image", void, 0, 0, 1, 0, 0, 0, 0) %image, <2 x i32> %coord, ptr addrspace(1) nocapture %data) local_unnamed_addr #0 {
entry:
  %call = tail call spir_func <4 x float> @_Z11read_imagef20ocl_image1d_array_roDv2_i(target("spirv.Image", void, 0, 0, 1, 0, 0, 0, 0) %image, <2 x i32> %coord) #3
  store <4 x float> %call, ptr addrspace(1) %data, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef20ocl_image1d_array_roDv2_i(target("spirv.Image", void, 0, 0, 1, 0, 0, 0, 0), <2 x i32>) local_unnamed_addr #1

attributes #0 = { convergent }
attributes #1 = { convergent nounwind }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind readonly }

