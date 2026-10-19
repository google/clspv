; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-LABEL: define spir_kernel void @foo(
; CHECK-NOT: call spir_func i32 @check_ptr
; CHECK: store i32 1, ptr addrspace(1) %out, align 4

define spir_func i32 @check_ptr(ptr %p) {
entry:
  %cmp = icmp ne ptr %p, null
  %res = select i1 %cmp, i32 1, i32 0
  ret i32 %res
}

define spir_kernel void @foo(ptr addrspace(1) %out) {
entry:
  %a = alloca i32, align 4
  %v = call spir_func i32 @check_ptr(ptr %a)
  store i32 %v, ptr addrspace(1) %out, align 4
  ret void
}
