; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@local_mem = internal addrspace(3) global i32 0

define void @global(ptr addrspace(1) %atomic) {
entry:
  %cast = addrspacecast ptr addrspace(1) %atomic to ptr addrspace(4)
  call spir_func void @_Z12atomic_storePU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 5, i32 3)
  ret void
}

define void @local(ptr addrspace(3) %atomic) {
entry:
  %cast = addrspacecast ptr addrspace(3) %atomic to ptr addrspace(4)
  call spir_func void @_Z12atomic_storePU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  call spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 5, i32 3)
  call spir_func void @_Z12atomic_storePU3AS4VU7_Atomicii(ptr addrspace(4) addrspacecast (ptr addrspace(3) @local_mem to ptr addrspace(4)), i32 100)
  ret void
}

declare spir_func void @_Z12atomic_storePU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func void @_Z21atomic_store_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)

; CHECK-LABEL: global
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(1) %atomic, i32 1, i32 68, i32 100)
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(1) %atomic, i32 1, i32 68, i32 102)

; CHECK-LABEL: local
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(3) %atomic, i32 2, i32 260, i32 100)
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(3) %atomic, i32 2, i32 0, i32 101)
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(3) %atomic, i32 2, i32 260, i32 102)
; CHECK: call void @_Z8spirv.op.228.{{.*}}(i32 228, ptr addrspace(3) @local_mem, i32 2, i32 260, i32 100)
