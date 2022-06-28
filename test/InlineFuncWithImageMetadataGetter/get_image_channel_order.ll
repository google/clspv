; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-image-metadata-getter
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t = type opaque

define dso_local spir_func i32 @get(%opencl.image2d_ro_t addrspace(1)* %img) {
entry:
  %call = call spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(%opencl.image2d_ro_t addrspace(1)* %img)
  ret i32 %call
}

declare spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(%opencl.image2d_ro_t addrspace(1)* %0)

define dso_local spir_func i32 @bar(%opencl.image2d_ro_t addrspace(1)* %img) {
entry:
  %call = call spir_func i32 @get(%opencl.image2d_ro_t addrspace(1)* %img)
  ret i32 %call
}

define dso_local spir_kernel void @foo(i32 addrspace(1)* align 4 %dst, %opencl.image2d_ro_t addrspace(1)* %image) {
entry:
  %call = call spir_func i32 @get(%opencl.image2d_ro_t addrspace(1)* %image)
  store i32 %call, i32 addrspace(1)* %dst, align 4
  ret void
}

; CHECK:  define dso_local spir_func i32 @bar
; CHECK:  call spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro
; CHECK:  ret i32

; CHECK:  define dso_local spir_kernel void @foo
; CHECK:  call spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro
; CHECK:  ret void
