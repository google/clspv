; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; %in is inferred to be a pointer to i32. The i32 loads through the i64 GEPs
; must be rewritten with the index scaled to i32 units.

; CHECK-LABEL: @low_half
; CHECK: [[idx:%[^ ]+]] = shl i32 %i, 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 [[idx]]
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4

; CHECK-LABEL: @low_half_offset
; CHECK: [[off:%[^ ]+]] = add i32 %i, 16
; CHECK: [[idx:%[^ ]+]] = shl i32 [[off]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 [[idx]]
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @low_half(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i) {
entry:
  %gep64 = getelementptr i64, ptr addrspace(1) %in, i32 %i
  %lo = load i32, ptr addrspace(1) %gep64, align 4
  %mul = shl i32 %i, 1
  %add = or disjoint i32 %mul, 1
  %gep32 = getelementptr i32, ptr addrspace(1) %in, i32 %add
  %hi = load i32, ptr addrspace(1) %gep32, align 4
  %sum = add i32 %lo, %hi
  store i32 %sum, ptr addrspace(1) %out, align 4
  ret void
}

define spir_kernel void @low_half_offset(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i) {
entry:
  %off = add i32 %i, 16
  %gep64 = getelementptr i64, ptr addrspace(1) %in, i32 %off
  %lo = load i32, ptr addrspace(1) %gep64, align 4
  %mul = shl i32 %i, 1
  %add = or disjoint i32 %mul, 1
  %gep32 = getelementptr i32, ptr addrspace(1) %in, i32 %add
  %hi = load i32, ptr addrspace(1) %gep32, align 4
  %sum = add i32 %lo, %hi
  store i32 %sum, ptr addrspace(1) %out, align 4
  ret void
}
