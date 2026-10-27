; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; A GEP of another source element type using a GEP that is replaced is folded
; into it: its users access the source of the replaced GEP at the sum of both
; offsets.

; The 12-byte struct is accessed as i64 through %src.k and %dst.k, so they are
; downgraded to GEPs of i32 along with %src and %dst, and %dst is then
; downgraded to a GEP of i8 for the i8 store through %dst.c. As %data is a
; physical pointer, the GEPs using them are not downgraded, such as the GEP of
; struct member %src.c using %src. %data is then inferred to point to i8, so
; %src is replaced, and %src.c must be folded into it.

; CHECK-LABEL: @struct_member_of_cast
; CHECK: [[src_idx:%[^ ]+]] = mul i64 %i, 3
; CHECK: [[k_off:%[^ ]+]] = mul i64 %k, 12
; CHECK: [[src_off:%[^ ]+]] = shl i64 [[src_idx]], 2
; CHECK: [[sum:%[^ ]+]] = add i64 [[k_off]], [[src_off]]
; CHECK: [[c_off:%[^ ]+]] = add i64 8, [[sum]]
; CHECK: [[c_gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %data, i64 [[c_off]]
; CHECK: [[c:%[^ ]+]] = load i8, ptr addrspace(1) [[c_gep]], align 1
; CHECK: store i8 [[c]]

; %in is also accessed as i32, so the i64 GEP %base is replaced, and the i32
; GEP %hi.gep using it must be folded into it.

; CHECK-LABEL: @sub_element_of_cast
; CHECK: [[off:%[^ ]+]] = shl i64 %i, 1
; CHECK: [[idx:%[^ ]+]] = add i64 %hi.idx, [[off]]
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i64 [[idx]]
; CHECK: [[hi:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK: add i32 %lo, [[hi]]

; The i64 GEP %gep using the i32 GEP %base, which is replaced as %a is an i64
; alloca, is folded into it. The offset of the store is then in units of i32,
; and must be converted into units of i64.

; CHECK-LABEL: @wide_store_of_cast
; CHECK: [[off:%[^ ]+]] = shl i64 %j, 1
; CHECK: [[sum:%[^ ]+]] = add i64 [[off]], %i
; CHECK: [[idx:%[^ ]+]] = lshr i64 [[sum]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i64, ptr %a, i64 [[idx]]
; CHECK: store i64 %v, ptr [[gep]], align 8

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

%struct.T = type { i32, [5 x i8] }

define spir_kernel void @struct_member_of_cast({ i64, i64, i64, i64 } %podargs) {
entry:
  %addr = extractvalue { i64, i64, i64, i64 } %podargs, 0
  %i = extractvalue { i64, i64, i64, i64 } %podargs, 1
  %j = extractvalue { i64, i64, i64, i64 } %podargs, 2
  %k = extractvalue { i64, i64, i64, i64 } %podargs, 3
  %data = inttoptr i64 %addr to ptr addrspace(1)
  %src = getelementptr %struct.T, ptr addrspace(1) %data, i64 %i
  %dst = getelementptr %struct.T, ptr addrspace(1) %data, i64 %j
  %src.k = getelementptr %struct.T, ptr addrspace(1) %src, i64 %k
  %w = load i64, ptr addrspace(1) %src.k, align 8
  %src.c = getelementptr %struct.T, ptr addrspace(1) %src, i64 %k, i32 1, i32 4
  %c = load i8, ptr addrspace(1) %src.c, align 4
  %dst.k = getelementptr %struct.T, ptr addrspace(1) %dst, i64 %k
  store i64 %w, ptr addrspace(1) %dst.k, align 8
  %dst.c = getelementptr %struct.T, ptr addrspace(1) %dst, i64 %k, i32 1, i32 4
  store i8 %c, ptr addrspace(1) %dst.c, align 4
  ret void
}

define spir_kernel void @sub_element_of_cast(ptr addrspace(1) %in, ptr addrspace(1) %out, i64 %i, i64 %j) {
entry:
  %lo.idx = shl i64 %j, 1
  %lo.gep = getelementptr i32, ptr addrspace(1) %in, i64 %lo.idx
  %lo = load i32, ptr addrspace(1) %lo.gep, align 4
  %base = getelementptr i64, ptr addrspace(1) %in, i64 %i
  %hi.idx = or disjoint i64 %lo.idx, 1
  %hi.gep = getelementptr i32, ptr addrspace(1) %base, i64 %hi.idx
  %hi = load i32, ptr addrspace(1) %hi.gep, align 4
  %sum = add i32 %lo, %hi
  store i32 %sum, ptr addrspace(1) %out, align 4
  ret void
}

define spir_kernel void @wide_store_of_cast(ptr addrspace(1) %out, i64 %v, i64 %i, i64 %j) {
entry:
  %a = alloca i64, i32 8, align 8
  %base = getelementptr i32, ptr %a, i64 %i
  %gep = getelementptr i64, ptr %base, i64 %j
  store i64 %v, ptr %gep, align 8
  %ld = load i64, ptr %a, align 8
  store i64 %ld, ptr addrspace(1) %out, align 8
  ret void
}
