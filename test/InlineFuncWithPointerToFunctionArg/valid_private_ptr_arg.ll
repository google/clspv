; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-pointer-function-arg
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; Valid functions that should NOT be inlined:
; CHECK-LABEL: define spir_func i32 @valid_load_store_gep(ptr %p, i32 %idx)
; CHECK-LABEL: define spir_func i32 @valid_forward_arg(ptr %p, i32 %idx)
; CHECK-NEXT: entry:
; CHECK-NEXT: call spir_func i32 @valid_load_store_gep(ptr %p, i32 %idx)
; CHECK-LABEL: define spir_func i32 @valid_ptr_element_gep(ptr %p, i32 %idx)

; Invalid functions that MUST be inlined and removed:
; CHECK-NOT: define spir_func {{.*}} @invalid_

; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: call spir_func i32 @valid_load_store_gep(ptr %a, i32 %n)
; CHECK: call spir_func i32 @valid_forward_arg(ptr %a, i32 %n)
; CHECK: call spir_func i32 @valid_ptr_element_gep(ptr %ptrs, i32 %n)
; Call to @valid_load_store_gep with a non-alloca/non-argument (GEP) operand must be inlined:
; CHECK-NOT: call spir_func i32 @valid_load_store_gep(ptr %caller_gep
; All calls to @invalid_* functions must be inlined:
; CHECK-NOT: call spir_func {{.*}} @invalid_
; CHECK: ret void

; Valid: direct load/store on %p and (chained) zero-first-index GEPs.
define spir_func i32 @valid_load_store_gep(ptr %p, i32 %idx) {
entry:
  %v0 = load i32, ptr %p, align 4
  store i32 %v0, ptr %p, align 4
  %gep = getelementptr [4 x [2 x i32]], ptr %p, i32 0, i32 %idx
  %gep2 = getelementptr [2 x i32], ptr %gep, i32 0, i32 1
  %v1 = load i32, ptr %gep2, align 4
  store i32 %v1, ptr %gep2, align 4
  ret i32 %v1
}

; Valid: forwarding an Argument directly to a valid callee.
define spir_func i32 @valid_forward_arg(ptr %p, i32 %idx) {
entry:
  %res = call spir_func i32 @valid_load_store_gep(ptr %p, i32 %idx)
  ret i32 %res
}

; Valid: GEP whose source element type is a pointer (array of resource pointers).
define spir_func i32 @valid_ptr_element_gep(ptr %p, i32 %idx) {
entry:
  %gep = getelementptr ptr addrspace(1), ptr %p, i32 %idx
  %ptr = load ptr addrspace(1), ptr %gep, align 4
  %v = load i32, ptr addrspace(1) %ptr, align 4
  ret i32 %v
}

; Invalid: returns a pointer to Private address space.
define spir_func ptr @invalid_return_ptr(ptr %p) {
entry:
  ret ptr %p
}

; Invalid: non-zero constant first GEP index.
define spir_func i32 @invalid_nonzero_gep(ptr %p) {
entry:
  %gep = getelementptr i32, ptr %p, i32 2
  %v = load i32, ptr %gep, align 4
  ret i32 %v
}

; Invalid: dynamic first GEP index.
define spir_func i32 @invalid_dynamic_gep(ptr %p, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr %p, i32 %idx
  %v = load i32, ptr %gep, align 4
  ret i32 %v
}

; Invalid: stores the private pointer as the value operand.
define spir_func void @invalid_store_ptr_val(ptr %p, ptr %dst) {
entry:
  store ptr %p, ptr %dst, align 4
  ret void
}

; Invalid: passes a GEP of %p (rather than %p itself) to a sub-call.
define spir_func i32 @invalid_subcall_gep(ptr %p) {
entry:
  %gep = getelementptr [4 x i32], ptr %p, i32 0, i32 1
  %v = call spir_func i32 @valid_load_store_gep(ptr %gep, i32 0)
  ret i32 %v
}

; Invalid: uses %p in a select instruction.
define spir_func i32 @invalid_select_user(ptr %p, ptr %q, i1 %cond) {
entry:
  %sel = select i1 %cond, ptr %p, ptr %q
  %v = load i32, ptr %sel, align 4
  ret i32 %v
}

; Invalid transitively: forwards %p to a callee that requires inlining.
define spir_func i32 @invalid_transitive_callee(ptr %p) {
entry:
  %v = call spir_func i32 @invalid_nonzero_gep(ptr %p)
  ret i32 %v
}

define spir_kernel void @foo(ptr addrspace(1) %out, i32 %n) {
entry:
  %a = alloca [4 x i32], align 4
  %b = alloca [4 x i32], align 4
  %ptrs = alloca [2 x ptr addrspace(1)], align 4
  %ptr_slot = alloca ptr, align 4

  ; Valid calls:
  %c1 = call spir_func i32 @valid_load_store_gep(ptr %a, i32 %n)
  %c2 = call spir_func i32 @valid_forward_arg(ptr %a, i32 %n)
  %c3 = call spir_func i32 @valid_ptr_element_gep(ptr %ptrs, i32 %n)

  ; Invalid call site to a valid function (passing a GEP instead of alloca/arg):
  %caller_gep = getelementptr [4 x i32], ptr %a, i32 0, i32 1
  %c4 = call spir_func i32 @valid_load_store_gep(ptr %caller_gep, i32 %n)

  ; Invalid callees:
  %ret_p = call spir_func ptr @invalid_return_ptr(ptr %a)
  %c5 = load i32, ptr %ret_p, align 4
  %c6 = call spir_func i32 @invalid_nonzero_gep(ptr %a)
  %c7 = call spir_func i32 @invalid_dynamic_gep(ptr %a, i32 %n)
  call spir_func void @invalid_store_ptr_val(ptr %a, ptr %ptr_slot)
  %c8 = call spir_func i32 @invalid_subcall_gep(ptr %a)
  %cond = icmp eq i32 %n, 0
  %c9 = call spir_func i32 @invalid_select_user(ptr %a, ptr %b, i1 %cond)
  %c10 = call spir_func i32 @invalid_transitive_callee(ptr %a)

  %s1 = add i32 %c1, %c2
  %s2 = add i32 %s1, %c3
  %s3 = add i32 %s2, %c4
  %s4 = add i32 %s3, %c5
  %s5 = add i32 %s4, %c6
  %s6 = add i32 %s5, %c7
  %s7 = add i32 %s6, %c8
  %s8 = add i32 %s7, %c9
  %s9 = add i32 %s8, %c10
  store i32 %s9, ptr addrspace(1) %out, align 4
  ret void
}

