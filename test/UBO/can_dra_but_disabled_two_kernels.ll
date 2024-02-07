; RUN: clspv-opt %s -o %t.ll -constant-args-ubo --passes=multi-version-ubo-functions,remove-unused-arguments
; RUN: FileCheck %s < %t.ll

; CHECK: define {{.*}} @k1
; CHECK: call {{.*}} [[bar1:@bar[a-zA-Z0-9_.]+]]()
; CHECK: define {{.*}} @k2
; CHECK: call {{.*}} [[bar2:@bar[a-zA-Z0-9_.]+]]()
; CHECK-DAG: define {{.*}} [[bar1]]()
; CHECK-DAG: [[res:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource.1
; CHECK-DAG: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res]], i32 0, i32 0, i32 0
; CHECK-DAG: load <4 x i32>, ptr addrspace(2) [[gep]]
; CHECK-DAG: define {{.*}} [[bar2]]()
; CHECK-DAG: [[res:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource.1
; CHECK-DAG: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res]], i32 0, i32 0, i32 0
; CHECK-DAG: load <4 x i32>, ptr addrspace(2) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func <4 x i32> @bar(ptr addrspace(2) nocapture readonly %data) {
entry:
  %0 = load <4 x i32>, ptr addrspace(2) %data, align 16
  ret <4 x i32> %0
}

define dso_local spir_kernel void @k1(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in) !clspv.pod_args_impl !17 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %3)
  store <4 x i32> %call, ptr addrspace(1) %1, align 16
  ret void
}

define dso_local spir_kernel void @k2(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in) !clspv.pod_args_impl !17 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %3)
  store <4 x i32> %call, ptr addrspace(1) %1, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x <4 x i32>] })

!17 = !{i32 2}

