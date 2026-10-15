; RUN: clspv-opt %s -o %t.ll --passes=inline-entry-points-pass
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-LABEL: define spir_func i32 @bar(
; CHECK-NOT: addrspace(4)
; CHECK: icmp eq ptr %p, null
; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: call spir_func i32 @bar(

define spir_func i32 @bar(ptr %p, i32 %x) {
entry:
  %cmp1 = icmp eq ptr %p, addrspacecast (ptr addrspace(4) null to ptr)
  %cmp2 = icmp eq ptr addrspace(4) null, null
  %cond = and i1 %cmp1, %cmp2
  %res = select i1 %cond, i32 0, i32 %x
  ret i32 %res
}

define spir_kernel void @foo(ptr addrspace(1) %out, i32 %n) {
entry:
  %a = alloca i32, align 4
  store i32 %n, ptr %a, align 4
  %call = call spir_func i32 @bar(ptr %a, i32 %n)
  store i32 %call, ptr addrspace(1) %out, align 4
  ret void
}
