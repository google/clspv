; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)

define spir_kernel void @foo(ptr addrspace(1) %unused_buf, ptr addrspace(1) %out) !kernel_arg_type !0 !kernel_arg_access_qual !1 {
entry:
  %cmp = icmp eq ptr addrspace(1) %unused_buf, null
  %v = select i1 %cmp, float 0.000000e+00, float 1.000000e+00
  store float %v, ptr addrspace(1) %out, align 4
  ret void
}

!0 = !{!"float*", !"float*"}
!1 = !{!"none", !"none"}
