; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; We expect a base of 268435456 (0x10000000) plus an offset of
; 2 * 4 = 8 => 268435464 (0x10000008)

; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: store i32 268435464, ptr addrspace(1) %out, align 4

define spir_kernel void @foo(ptr addrspace(1) %out) {
entry:
  %slot = alloca ptr addrspace(1), align 4
  %ld = load ptr addrspace(1), ptr %slot, align 4
  %gep = getelementptr i32, ptr addrspace(1) %ld, i32 2
  %pti = ptrtoint ptr addrspace(1) %gep to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}
