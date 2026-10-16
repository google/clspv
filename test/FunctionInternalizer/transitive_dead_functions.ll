; RUN: clspv-opt %s -o %t.ll --passes=function-internalizer
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-NOT: @dead_leaf
; CHECK-NOT: @dead_mid
; CHECK-NOT: @dead_top
; CHECK-LABEL: define spir_func i32 @live_helper(
; CHECK-LABEL: define spir_kernel void @main_kernel(

define spir_func i32 @dead_leaf(i32 %x) {
entry:
  %add = add i32 %x, 1
  ret i32 %add
}

define spir_func i32 @dead_mid(i32 %x) {
entry:
  %call = call spir_func i32 @dead_leaf(i32 %x)
  ret i32 %call
}

define spir_func i32 @dead_top(i32 %x) {
entry:
  %call = call spir_func i32 @dead_mid(i32 %x)
  ret i32 %call
}

define spir_func i32 @live_helper(i32 %x) {
entry:
  %add = add i32 %x, 42
  ret i32 %add
}

define spir_kernel void @main_kernel(ptr addrspace(1) %out, i32 %x) {
entry:
  %call = call spir_func i32 @live_helper(i32 %x)
  store i32 %call, ptr addrspace(1) %out, align 4
  ret void
}
