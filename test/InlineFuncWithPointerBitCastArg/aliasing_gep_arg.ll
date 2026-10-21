; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-pointer-cast-arg
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.Inner = type { i32, float }
%struct.Outer = type { %struct.Inner, i32 }

; CHECK-LABEL: define spir_func i32 @callee(ptr addrspace(1) %p)
; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: %[[OUTER:[a-zA-Z0-9_]+]] = getelementptr %struct.Outer, ptr addrspace(1) %base, i32 %idx
; CHECK-NEXT: %[[INNER:[a-zA-Z0-9_]+]] = getelementptr %struct.Outer, ptr addrspace(1) %[[OUTER]], i32 0, i32 0
; CHECK-NEXT: %[[CALL:[a-zA-Z0-9_]+]] = call spir_func i32 @callee(ptr addrspace(1) %[[INNER]])

define spir_func i32 @callee(ptr addrspace(1) %p) #0 {
entry:
  %gep = getelementptr %struct.Inner, ptr addrspace(1) %p, i32 0, i32 0
  %v = load i32, ptr addrspace(1) %gep, align 4
  ret i32 %v
}

define spir_kernel void @foo(ptr addrspace(1) %base, ptr addrspace(1) %out, i32 %idx) {
entry:
  %outer = getelementptr %struct.Outer, ptr addrspace(1) %base, i32 %idx
  %call = call spir_func i32 @callee(ptr addrspace(1) %outer)
  store i32 %call, ptr addrspace(1) %out, align 4
  ret void
}

attributes #0 = { noinline }
