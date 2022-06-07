; RUN: clspv-opt %s -o %t.ll -opaque-pointers --passes=specialize-image-types
; RUN: FileCheck %s < %t.ll

; CHECK: @bar(ptr addrspace(1) %t)
; CHECK: call spir_func void @_Z12write_imagef20ocl_image2d_wo.floatDv2_iDv4_f(ptr addrspace(1) %t
; CHECK: @foo(ptr addrspace(1) %t)
; CHECK: call spir_func void @bar(ptr addrspace(1) %t)
; CHECK: @test(ptr addrspace(1) %t)
; CHECK: call spir_func void @foo(ptr addrspace(1) %t)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_func void @bar(ptr addrspace(1) %t) {
entry:
  call spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(ptr addrspace(1) %t, <2 x i32> zeroinitializer, <4 x float> zeroinitializer)
  ret void
}

declare spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(ptr addrspace(1), <2 x i32>, <4 x float>) #1

define dso_local spir_func void @foo(ptr addrspace(1) %t) {
entry:
  call spir_func void @bar(ptr addrspace(1) %t)
  ret void
}

define dso_local spir_kernel void @test(ptr addrspace(1) %t) !clspv.pod_args_impl !7 {
entry:
  call spir_func void @foo(ptr addrspace(1) %t)
  ret void
}

!7 = !{i32 2}

