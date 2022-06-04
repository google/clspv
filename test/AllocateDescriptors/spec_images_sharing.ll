; RUN: clspv-opt %s -o %t.ll -opaque-pointers --passes=specialize-image-types,allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: @foo
; CHECK: [[res:%[a-zA-Z0-9_.]+]] = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 7, i32 0, i32 0, i32 0, %ocl_image1d_wo.float zeroinitializer)
; CHECK: (ptr addrspace(1) [[res]],
; CHECK: @bar
; CHECK: [[res:%[a-zA-Z0-9_.]+]] = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 7, i32 0, i32 0, i32 0, %ocl_image1d_wo.float zeroinitializer)
; CHECK: (ptr addrspace(1) [[res]],

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) %t) !clspv.pod_args_impl !7 {
entry:
  call spir_func void @_Z12write_imagef14ocl_image1d_woiDv4_f(ptr addrspace(1) %t, i32 0, <4 x float> zeroinitializer)
  ret void
}

declare spir_func void @_Z12write_imagef14ocl_image1d_woiDv4_f(ptr addrspace(1), i32, <4 x float>)

define dso_local spir_kernel void @bar(ptr addrspace(1) %t) !clspv.pod_args_impl !7 {
entry:
  call spir_func void @_Z12write_imagef14ocl_image1d_woiDv4_f(ptr addrspace(1) %t, i32 0, <4 x float> zeroinitializer)
  ret void
}

!7 = !{i32 2}

