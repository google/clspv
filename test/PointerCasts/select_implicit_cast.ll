; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.Inner = type { i32, float }
%struct.Outer = type { %struct.Inner, i32 }

; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: %[[OUTER:[a-zA-Z0-9_]+]] = getelementptr %struct.Outer, ptr addrspace(1) %a, i32 0, i32 0, i32 0
; CHECK: %[[INNER:[a-zA-Z0-9_]+]] = getelementptr %struct.Inner, ptr addrspace(1) %b, i32 0, i32 0
; CHECK: %[[SEL:[a-zA-Z0-9_]+]] = select i1 %cond, ptr addrspace(1) %[[OUTER]], ptr addrspace(1) %[[INNER]]

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, ptr addrspace(1) %out, i1 %cond) {
entry:
  %outer = getelementptr %struct.Outer, ptr addrspace(1) %a, i32 0
  %inner = getelementptr %struct.Inner, ptr addrspace(1) %b, i32 0
  %sel = select i1 %cond, ptr addrspace(1) %outer, ptr addrspace(1) %inner
  %gep = getelementptr %struct.Inner, ptr addrspace(1) %sel, i32 0, i32 0
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}
