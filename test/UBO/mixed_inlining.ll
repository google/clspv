; RUN: clspv-opt -constant-args-ubo %s -o %t.ll --passes=multi-version-ubo-functions,remove-unused-arguments
; RUN: FileCheck %s < %t.ll

; Note: this test would produce invalid SPIR-V.

; The call to bar in k1 requires inlining
; CHECK: define {{.*}} @k1
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 %{{[^ ]+}}, ptr addrspace(2)
; CHECK: load <4 x i32>, ptr addrspace(2) [[sel]]

; The call to bar in k2 is specialized
; CHECK: define {{.*}} @k2
; CHECK: call {{.*}} [[bar2:@bar[a-zA-Z0-9_.]+]]()

; CHECK: define {{.*}} [[bar2]]
; CHECK: [[res:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res]], i32 0, i32 0, i32 0
; CHECK: load <4 x i32>, ptr addrspace(2) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func <4 x i32> @bar(ptr addrspace(2) nocapture readonly %data) {
entry:
  %0 = load <4 x i32>, ptr addrspace(2) %data, align 16
  ret <4 x i32> %0
}

define spir_kernel void @k1(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in1, ptr addrspace(2) nocapture readonly align 16 %in2, { i32 } %podargs) !clspv.pod_args_impl !18 !kernel_arg_map !19 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 1, i32 2, i32 2, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %5 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %4, i32 0, i32 0, i32 0
  %6 = call ptr addrspace(9) @_Z14clspv.resource.3(i32 -1, i32 3, i32 5, i32 3, i32 3, i32 0, { { i32 } } zeroinitializer)
  %7 = getelementptr { { i32 } }, ptr addrspace(9) %6, i32 0, i32 0
  %8 = load { i32 }, ptr addrspace(9) %7, align 4
  %a = extractvalue { i32 } %8, 0
  %cmp.i = icmp eq i32 %a, 0
  %in1.in2 = select i1 %cmp.i, ptr addrspace(2) %3, ptr addrspace(2) %5
  %call.i = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %in1.in2) #2
  store <4 x i32> %call.i, ptr addrspace(1) %1, align 16
  ret void
}

define dso_local spir_kernel void @k2(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in) !clspv.pod_args_impl !18 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %3) #2
  store <4 x i32> %call, ptr addrspace(1) %1, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x <4 x i32>] })

declare ptr addrspace(2) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [4096 x <4 x i32>] })

declare ptr addrspace(9) @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { { i32 } })

!18 = !{i32 2}
!19 = !{!20, !21, !22, !23}
!20 = !{!"out", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!21 = !{!"in1", i32 1, i32 1, i32 0, i32 0, !"buffer_ubo"}
!22 = !{!"in2", i32 2, i32 2, i32 0, i32 0, !"buffer_ubo"}
!23 = !{!"a", i32 3, i32 3, i32 0, i32 4, !"pod_pushconstant"}

