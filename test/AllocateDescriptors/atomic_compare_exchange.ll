; RUN: clspv-opt -opaque-pointers %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i64] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x i64] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.4(i32 0, i32 4, i32 0, i32 4, i32 4, i32 0, { [0 x i32] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 4 %b, ptr addrspace(1) align 8 %c, ptr addrspace(1) align 8 %d, ptr addrspace(1) align 4 %e) !clspv.pod_args_impl !7 {
entry:
  %tmp1 = alloca i32, align 4
  %tmp3 = alloca i64, align 8
  %tmp4 = alloca i64, align 8
  %0 = addrspacecast ptr addrspace(1) %a to ptr addrspace(4)
  %tmp1.ascast = addrspacecast ptr %tmp1 to ptr addrspace(4)
  %call = call spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPU3AS4VU7_AtomiciPU3AS4ii(ptr addrspace(4) %0, ptr addrspace(4) %tmp1.ascast, i32 0)
  %1 = addrspacecast ptr addrspace(1) %a to ptr addrspace(4)
  %2 = addrspacecast ptr addrspace(1) %e to ptr addrspace(4)
  %call1 = call spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPU3AS4VU7_AtomiciPU3AS4ii(ptr addrspace(4) %1, ptr addrspace(4) %2, i32 0)
  %3 = addrspacecast ptr addrspace(1) %c to ptr addrspace(4)
  %tmp3.ascast = addrspacecast ptr %tmp3 to ptr addrspace(4)
  %call2 = call spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiclPU3AS4ll12memory_orderS4_(ptr addrspace(4) %3, ptr addrspace(4) %tmp3.ascast, i64 0, i32 4, i32 0)
  %4 = addrspacecast ptr addrspace(1) %d to ptr addrspace(4)
  %tmp4.ascast = addrspacecast ptr %tmp4 to ptr addrspace(4)
  %call3 = call spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomicmPU3AS4mm(ptr addrspace(4) %4, ptr addrspace(4) %tmp4.ascast, i64 0)
  %5 = addrspacecast ptr addrspace(1) %b to ptr addrspace(4)
  %call4 = call spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomicjPU3AS4jj(ptr addrspace(4) %5, ptr addrspace(4) %tmp4.ascast, i32 0)
  ret void
}

declare spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPU3AS4VU7_AtomiciPU3AS4ii(ptr addrspace(4), ptr addrspace(4), i32)
declare spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiclPU3AS4ll12memory_orderS4_(ptr addrspace(4), ptr addrspace(4), i64, i32, i32)
declare spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomicmPU3AS4mm(ptr addrspace(4), ptr addrspace(4), i64)
declare spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomicjPU3AS4jj(ptr addrspace(4), ptr addrspace(4), i32)

!7 = !{i32 1}

