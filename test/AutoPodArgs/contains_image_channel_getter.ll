; RUN: clspv-opt --passes=auto-pod-args %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_func i32 @bar(ptr addrspace(1) %image) {
entry:
  %call = call spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(ptr addrspace(1) %image)
  ret i32 %call
}

declare spir_func i32 @_Z23get_image_channel_order14ocl_image2d_ro(ptr addrspace(1) %0)

define dso_local spir_func i32 @foo(ptr addrspace(1) %image) {
entry:
  %call = call spir_func i32 @bar(ptr addrspace(1) %image)
  ret i32 %call
}

define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %dst, ptr addrspace(1) %image, i32 %off) {
entry:
  %call = call spir_func i32 @foo(ptr addrspace(1) %image)
  %add = add i32 %call, %off
  store i32 %add, ptr addrspace(1) %dst, align 4
  ret void
}

; CHECK: define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %dst, ptr addrspace(1) %image, i32 %off) !clspv.pod_args_impl [[MD:![^ ]+]]
; CHECK: [[MD]] = !{i32 3}
