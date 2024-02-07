; RUN: clspv-opt -constant-args-ubo %s -o %t.ll --passes=multi-version-ubo-functions,remove-unused-arguments
; RUN: FileCheck %s < %t.ll

; CHECK: define {{.*}} @k1
; CHECK: call {{.*}} [[bar1:@bar[a-zA-Z0-9_.]+]]()
; CHECK: define {{.*}} @k2
; CHECK: call {{.*}} [[bar2:@bar[a-zA-Z0-9_.]+]]()

; CHECK: define {{.*}} [[bar2]]()
; CHECK-DAG: [[res1:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource
; CHECK-DAG: [[res2:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource
; CHECK-DAG: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res1]]
; CHECK-DAG: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res2]]
; CHECK-DAG: [[ld1:%[a-zA-Z0-9_.]+]] = load <4 x i32>, ptr addrspace(2) [[gep1]]
; CHECK-DAG: [[ld2:%[a-zA-Z0-9_.]+]] = load <4 x i32>, ptr addrspace(2) [[gep2]]

; CHECK: define {{.*}} [[bar1]]()
; CHECK-DAG: [[res1:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource
; CHECK-DAG: [[res2:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource
; CHECK-DAG: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res1]]
; CHECK-DAG: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) [[res2]]
; CHECK-DAG: [[ld1:%[a-zA-Z0-9_.]+]] = load <4 x i32>, ptr addrspace(2) [[gep1]]
; CHECK-DAG: [[ld2:%[a-zA-Z0-9_.]+]] = load <4 x i32>, ptr addrspace(2) [[gep2]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_func <4 x i32> @bar(ptr addrspace(2) nocapture readonly %in1, ptr addrspace(2) nocapture readonly %in2) {
entry:
  %0 = load <4 x i32>, ptr addrspace(2) %in1, align 16
  %1 = load <4 x i32>, ptr addrspace(2) %in2, align 16
  %add = add <4 x i32> %1, %0
  ret <4 x i32> %add
}

define dso_local spir_kernel void @k1(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in1, ptr addrspace(2) nocapture readonly align 16 %in2) !clspv.pod_args_impl !18 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 1, i32 2, i32 2, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %5 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %4, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %3, ptr addrspace(2) %5) #2
  store <4 x i32> %call, ptr addrspace(1) %1, align 16
  ret void
}

define dso_local spir_kernel void @k2(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in1, ptr addrspace(2) nocapture readonly align 16 %in2) !clspv.pod_args_impl !18 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %3 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 1, i32 2, i32 2, i32 0, { [4096 x <4 x i32>] } zeroinitializer)
  %5 = getelementptr { [4096 x <4 x i32>] }, ptr addrspace(2) %4, i32 0, i32 0, i32 0
  %call = tail call spir_func <4 x i32> @bar(ptr addrspace(2) %5, ptr addrspace(2) %3) #2
  store <4 x i32> %call, ptr addrspace(1) %1, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x <4 x i32>] })

declare ptr addrspace(2) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [4096 x <4 x i32>] })

!18 = !{i32 2}

