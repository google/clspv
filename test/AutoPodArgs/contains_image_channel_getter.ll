; RUN: clspv-opt --passes=auto-pod-args %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_ro_t = type opaque

define dso_local spir_func i32 @bar(%opencl.image2d_ro_t addrspace(1)* %image) {
entry:
  %call = call spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(%opencl.image2d_ro_t addrspace(1)* %image)
  ret i32 %call
}

declare spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(%opencl.image2d_ro_t addrspace(1)* %0)

define dso_local spir_func i32 @foo(%opencl.image2d_ro_t addrspace(1)* %image) {
entry:
  %call = call spir_func i32 @bar(%opencl.image2d_ro_t addrspace(1)* %image)
  ret i32 %call
}

define dso_local spir_kernel void @test(i32 addrspace(1)* align 4 %dst, %opencl.image2d_ro_t addrspace(1)* %image, i32 %off) {
entry:
  %call = call spir_func i32 @foo(%opencl.image2d_ro_t addrspace(1)* %image)
  %add = add i32 %call, %off
  store i32 %add, i32 addrspace(1)* %dst, align 4
  ret void
}

; CHECK: define dso_local spir_kernel void @test(i32 addrspace(1)* align 4 %dst, %opencl.image2d_ro_t addrspace(1)* %image, i32 %off) !clspv.pod_args_impl [[MD:![^ ]+]]
; CHECK: [[MD]] = !{i32 3}
