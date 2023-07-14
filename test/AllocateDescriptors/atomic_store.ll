; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i64] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x i64] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 4 %b, ptr addrspace(1) align 8 %c, ptr addrspace(1) align 8 %d) !clspv.pod_args_impl !8 {
entry:
  call spir_func void @_Z12atomic_storePU3AS1VU7_Atomicjj(ptr addrspace(1) %a, i32 0)
  call spir_func void @_Z12atomic_storePU3AS1VU7_Atomicii(ptr addrspace(1) %b, i32 0)
  call spir_func void @_Z21atomic_store_explicitPU3AS1VU7_Atomicmm12memory_order(ptr addrspace(1) %c, i64 0, i32 3)
  call spir_func void @_Z21atomic_store_explicitPU3AS1VU7_Atomicll12memory_order(ptr addrspace(1) %d, i64 0, i32 0)
  ret void
}

declare spir_func void @_Z12atomic_storePU3AS1VU7_Atomicjj(ptr addrspace(1), i32)
declare spir_func void @_Z12atomic_storePU3AS1VU7_Atomicii(ptr addrspace(1), i32)
declare spir_func void @_Z21atomic_store_explicitPU3AS1VU7_Atomicmm12memory_order(ptr addrspace(1), i64, i32)
declare spir_func void @_Z21atomic_store_explicitPU3AS1VU7_Atomicll12memory_order(ptr addrspace(1), i64, i32)

!8 = !{i32 1}

