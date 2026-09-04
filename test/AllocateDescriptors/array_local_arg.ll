; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x i32] zeroinitializer)
; CHECK: getelementptr [0 x i32], ptr addrspace(3) {{.*}}, i32 0, i32 0

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @test(ptr addrspace(3) %wg, ptr addrspace(1) %out) !clspv.pod_args_impl !1 {
entry:
  %gep = getelementptr inbounds [4 x i32], ptr addrspace(3) %wg, i32 0, i32 1
  %ld = load i32, ptr addrspace(3) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}

!1 = !{i32 1}
