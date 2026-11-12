; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

%struct.packed = type <{ [12 x i8], <2 x i8>, <3 x i8> }>

; 1. Valid [N x i8] GEP upgrade to scalar i32 when element size divides target.
; CHECK-LABEL: define spir_kernel void @valid_byte_array_upgrade(
; CHECK: [[idx:%[^ ]+]] = shl i64 %i, 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %p, i64 [[idx]]
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4
define spir_kernel void @valid_byte_array_upgrade(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %i) {
entry:
  %gep = getelementptr [8 x i8], ptr addrspace(1) %p, i64 %i
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}

; 2. A [N x i8] GEP produced by RewritePackedStructs must not be upgraded back
; to the packed struct type; instead runOnImplicitCasts lowers the struct GEP
; into the [N x i8] GEP.
; CHECK-LABEL: define spir_kernel void @no_upgrade_byte_array_to_struct(
; CHECK-NOT: getelementptr %struct.packed
; CHECK: [[gep:%[^ ]+]] = getelementptr [18 x i8], ptr addrspace(1) %p, i64 %i, i32 12
; CHECK: ptrtoaddr ptr addrspace(1) [[gep]] to i64
define spir_kernel void @no_upgrade_byte_array_to_struct(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %i) {
entry:
  %0 = getelementptr [18 x i8], ptr addrspace(1) %p, i64 %i
  %1 = getelementptr [18 x i8], ptr addrspace(1) %0, i32 0
  %2 = getelementptr %struct.packed, ptr addrspace(1) %1, i32 0, i32 1
  %addr = ptrtoaddr ptr addrspace(1) %2 to i64
  store i64 %addr, ptr addrspace(1) %out, align 8
  ret void
}

; 3. [0 x i8] GEP must not cause division by zero or be upgraded.
; CHECK-LABEL: define spir_kernel void @zero_sized_byte_array(
; CHECK: [[gep:%[^ ]+]] = getelementptr [0 x i8], ptr addrspace(1) %p, i64 %i
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4
define spir_kernel void @zero_sized_byte_array(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %i) {
entry:
  %gep = getelementptr [0 x i8], ptr addrspace(1) %p, i64 %i
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}

; 4. [5 x i8] (40 bits) with mul by 2 (coef = 80) feeding i16 (16 bits):
; coef % coef_target == 0, but 40 % 16 != 0, so it must not be upgraded.
; CHECK-LABEL: define spir_kernel void @non_divisible_smaller_gt_target(
; CHECK: [[idx:%[^ ]+]] = shl i64 %i, 1
; CHECK: [[gep:%[^ ]+]] = getelementptr [5 x i8], ptr addrspace(1) %p, i64 [[idx]]
; CHECK: load i16, ptr addrspace(1) [[gep]], align 2
define spir_kernel void @non_divisible_smaller_gt_target(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %i) {
entry:
  %idx = shl i64 %i, 1
  %gep = getelementptr [5 x i8], ptr addrspace(1) %p, i64 %idx
  %ld = load i16, ptr addrspace(1) %gep, align 2
  store i16 %ld, ptr addrspace(1) %out, align 2
  ret void
}

; 5. [6 x i8] (48 bits) with shl by 2 (coef = 192) feeding i64 (64 bits):
; coef % coef_target == 0, but 64 % 48 != 0 and 48 % 32 != 0, so i64 and i32
; must be rejected and it falls back to i16 (48 % 16 == 0, stride * 3).
; CHECK-LABEL: define spir_kernel void @non_divisible_target_gt_smaller(
; CHECK: [[idx:%[^ ]+]] = shl i64 %i, 2
; CHECK: [[mul:%[^ ]+]] = mul i64 [[idx]], 3
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %p, i64 [[mul]]
; CHECK: load i64, ptr addrspace(1) [[gep]], align 8
define spir_kernel void @non_divisible_target_gt_smaller(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %i) {
entry:
  %idx = shl i64 %i, 2
  %gep = getelementptr [6 x i8], ptr addrspace(1) %p, i64 %idx
  %ld = load i64, ptr addrspace(1) %gep, align 8
  store i64 %ld, ptr addrspace(1) %out, align 8
  ret void
}

; 6. [3 x i8] (24 bits) with known trailing zeros feeding i32 (32 bits) and
; i64 (64 bits): 32 / 24 == 1 and 64 / 24 == 2 are powers of two under
; truncating division, but 32 % 24 != 0 and 64 % 24 != 0, so knownMultiple
; must not upgrade the GEP.
; CHECK-LABEL: define spir_kernel void @non_divisible_known_multiple(
; CHECK: [[gep:%[^ ]+]] = getelementptr [3 x i8], ptr addrspace(1) %p, i64 %stride
; CHECK: load i64, ptr addrspace(1) [[gep]], align 8
define spir_kernel void @non_divisible_known_multiple(ptr addrspace(1) %p, ptr addrspace(1) %out, i64 %n) {
entry:
  %sext = shl i64 %n, 32
  %stride = ashr exact i64 %sext, 30
  %gep = getelementptr [3 x i8], ptr addrspace(1) %p, i64 %stride
  %ld = load i64, ptr addrspace(1) %gep, align 8
  store i64 %ld, ptr addrspace(1) %out, align 8
  ret void
}
