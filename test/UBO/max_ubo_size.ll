; RUN: clspv-opt -constant-args-ubo -max-ubo-size=64 %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; Checking that -max-ubo-size affects the number of elements in the UBO array.
; Struct alloca size is 32, so expect 2 elements with max size of 64.
; CHECK: [[s:%[a-zA-Z0-9_.]+]] = type { i32, [12 x i8], i32, [12 x i8] }
; CHECK: call ptr addrspace(2) @_Z14clspv.resource
; CHECK-SAME: { [2 x [[s]]] } zeroinitializer

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.s = type { i32, [12 x i8], i32, [12 x i8] }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c) !clspv.pod_args_impl !12 {
entry:
  %0 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %1 = load i32, ptr addrspace(5) %0, align 16
  %2 = getelementptr inbounds %struct.s, ptr addrspace(2) %c, i32 %1, i32 0
  %3 = load i32, ptr addrspace(2) %2, align 16
  %4 = getelementptr inbounds %struct.s, ptr addrspace(1) %data, i32 %1, i32 0
  store i32 %3, ptr addrspace(1) %4, align 16
  %5 = getelementptr inbounds %struct.s, ptr addrspace(2) %c, i32 %1, i32 2
  %6 = load i32, ptr addrspace(2) %5, align 16
  %7 = getelementptr inbounds %struct.s, ptr addrspace(1) %data, i32 %1, i32 2
  store i32 %6, ptr addrspace(1) %7, align 16
  ret void
}

!12 = !{i32 2}

