; RUN: clspv-opt %s -o %t.ll --passes=inline-entry-points-pass
; RUN: FileCheck %s < %t.ll
;
; Verify that InlineEntryPointsPass only inlines into entry-point kernels
; top-down, without redundantly inlining callees into non-kernel functions.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-LABEL: define spir_func i32 @leaf(
; CHECK: ret i32
; CHECK-LABEL: define spir_func i32 @mid(
; CHECK: call spir_func i32 @leaf(
; CHECK-LABEL: define spir_kernel void @entry(
; CHECK-NOT: call spir_func
; CHECK: add i32
; CHECK: mul i32
; CHECK: ret void

define spir_func i32 @leaf(ptr addrspace(4) %p, i32 %x) {
entry:
  %v = load i32, ptr addrspace(4) %p, align 4
  %add = add i32 %v, %x
  ret i32 %add
}

define spir_func i32 @mid(ptr addrspace(4) %p, i32 %x) {
entry:
  %call = call spir_func i32 @leaf(ptr addrspace(4) %p, i32 %x)
  %mul = mul i32 %call, 2
  ret i32 %mul
}

define spir_kernel void @entry(ptr addrspace(1) %out, i32 %n) {
entry:
  %a = alloca i32, align 4
  store i32 %n, ptr %a, align 4
  %gen = addrspacecast ptr %a to ptr addrspace(4)
  %res = call spir_func i32 @mid(ptr addrspace(4) %gen, i32 %n)
  store i32 %res, ptr addrspace(1) %out, align 4
  ret void
}
