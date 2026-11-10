; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; GetAtomicCallDataTy must look past a call's own return type (which, for
; several atomic builtins, is void/bool and unrelated to the type of the
; data they operate on) to find the actual data type, otherwise the pass
; either divides by a zero-sized type, or silently retypes storage to
; match the wrong (void/bool) "data type".

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; atomic_init's data type is its "value" operand (float), not its void
; return type.
; CHECK-LABEL: define spir_kernel void @atomic_init_test(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %buf, i32 %idx
; CHECK: call void @_Z11atomic_initPU3AS1VU7_Atomicff(ptr addrspace(1) [[gep]], float %v)
define spir_kernel void @atomic_init_test(ptr addrspace(1) %buf, float %v, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
  call void @_Z11atomic_initPU3AS1VU7_Atomicff(ptr addrspace(1) %gep, float %v)
  ret void
}

; atomic_flag storage is an i32, regardless of the call's own void/bool
; return type.
; CHECK-LABEL: define spir_kernel void @atomic_flag_test(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %flag, i32 %idx
; CHECK: call i1 @_Z24atomic_flag_test_and_setPU3AS1VU7_Atomici(ptr addrspace(1) [[gep]])
; CHECK: call void @_Z17atomic_flag_clearPU3AS1VU7_Atomici(ptr addrspace(1) [[gep]])
define spir_kernel void @atomic_flag_test(ptr addrspace(1) %flag, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr addrspace(1) %flag, i32 %idx
  %was_set = call i1 @_Z24atomic_flag_test_and_setPU3AS1VU7_Atomici(ptr addrspace(1) %gep)
  call void @_Z17atomic_flag_clearPU3AS1VU7_Atomici(ptr addrspace(1) %gep)
  ret void
}

; atomic_compare_exchange_strong's data type is its "desired" operand
; (float), not its bool return type.
; CHECK-LABEL: define spir_kernel void @atomic_cmpxchg_test(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %buf, i32 %idx
; CHECK: call i1 @_Z30atomic_compare_exchange_strongPU3AS1VU7_AtomicfPU3AS1ff(ptr addrspace(1) [[gep]], ptr addrspace(1) %expected, float %desired)
define spir_kernel void @atomic_cmpxchg_test(ptr addrspace(1) %buf, ptr addrspace(1) %expected, float %desired, i32 %idx) {
entry:
  %gep = getelementptr float, ptr addrspace(1) %buf, i32 %idx
  %ok = call i1 @_Z30atomic_compare_exchange_strongPU3AS1VU7_AtomicfPU3AS1ff(ptr addrspace(1) %gep, ptr addrspace(1) %expected, float %desired)
  ret void
}

; atomic_work_item_fence has no pointer operand: it must not be treated as
; an atomic memory access on an unrelated buffer GEP.
; CHECK-LABEL: define spir_kernel void @atomic_fence_test(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
; CHECK: load i32, ptr addrspace(1) [[gep]]
define spir_kernel void @atomic_fence_test(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
  %x = load i32, ptr addrspace(1) %gep, align 4
  call void @_Z22atomic_work_item_fencej12memory_order10memory_scope(i32 1, i32 0, i32 1)
  ret void
}

; spirv.atomic_xor (emitted for vstore_half) is in the Clspv builtin group,
; not Atomic, but its i32 storage must still be recognized as an integer
; atomic access, so a float atomic sharing the same buffer does not retype
; it to float underneath the xor.
; CHECK-LABEL: define spir_kernel void @vstore_half_and_float_atomic(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
; CHECK: call i32 @spirv.atomic_xor(ptr addrspace(1) [[gep]], i32 1, i32 0, i32 255)
; CHECK: call float @_Z8spirv.op.6035.PU3AS1fjjf(i32 6035, ptr addrspace(1) %buf, i32 2, i32 0, float %v)
define spir_kernel void @vstore_half_and_float_atomic(ptr addrspace(1) %buf, float %v, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr addrspace(1) %buf, i32 %idx
  %old = call i32 @spirv.atomic_xor(ptr addrspace(1) %gep, i32 1, i32 0, i32 255)
  %oldf = call float @_Z8spirv.op.6035.PU3AS1fjjf(i32 6035, ptr addrspace(1) %buf, i32 2, i32 0, float %v)
  ret void
}

declare void @_Z11atomic_initPU3AS1VU7_Atomicff(ptr addrspace(1), float)
declare i1 @_Z24atomic_flag_test_and_setPU3AS1VU7_Atomici(ptr addrspace(1))
declare void @_Z17atomic_flag_clearPU3AS1VU7_Atomici(ptr addrspace(1))
declare i1 @_Z30atomic_compare_exchange_strongPU3AS1VU7_AtomicfPU3AS1ff(ptr addrspace(1), ptr addrspace(1), float)
declare void @_Z22atomic_work_item_fencej12memory_order10memory_scope(i32, i32, i32)
declare i32 @spirv.atomic_xor(ptr addrspace(1), i32, i32, i32)
declare float @_Z8spirv.op.6035.PU3AS1fjjf(i32, ptr addrspace(1), i32, i32, float)
