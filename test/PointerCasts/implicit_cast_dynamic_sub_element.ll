; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll
; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s --check-prefix=REPLACE < %t.ll

; %off is not a multiple of the size of i64, so the GEP of i32, upgraded from
; the GEP of i8, cannot be turned into an i64 GEP: it must be left for
; ReplacePointerBitcastPass, which loads the i64 and extracts the i32 at %off.

; CHECK-LABEL: @sub_element
; CHECK: [[base:%[^ ]+]] = getelementptr i64, ptr addrspace(1) %in, i32 %i
; CHECK: [[off32:%[^ ]+]] = ashr exact i32 %off, 2
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[base]], i32 [[off32]]
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4

; REPLACE-LABEL: @sub_element
; REPLACE: [[base:%[^ ]+]] = getelementptr i64, ptr addrspace(1) %in, i32 %i
; REPLACE: [[off32:%[^ ]+]] = ashr exact i32 %off, 2
; REPLACE: [[idx:%[^ ]+]] = lshr i32 [[off32]], 1
; REPLACE: [[gep:%[^ ]+]] = getelementptr i64, ptr addrspace(1) [[base]], i32 [[idx]]
; REPLACE: [[ld:%[^ ]+]] = load i64, ptr addrspace(1) [[gep]], align 8
; REPLACE: [[and:%[^ ]+]] = and i32 [[off32]], 1
; REPLACE: [[vec:%[^ ]+]] = bitcast i64 [[ld]] to <2 x i32>
; REPLACE: [[val:%[^ ]+]] = extractelement <2 x i32> [[vec]], i32 [[and]]
; REPLACE: store i32 [[val]], ptr addrspace(1) %out, align 4

; %off is known to be a multiple of the size of i64.

; CHECK-LABEL: @element
; CHECK: [[off32:%[^ ]+]] = ashr exact i32 %off, 2
; CHECK: [[idx:%[^ ]+]] = lshr i32 [[off32]], 1
; CHECK: [[add:%[^ ]+]] = add i32 %i, [[idx]]
; CHECK: [[gep:%[^ ]+]] = getelementptr i64, ptr addrspace(1) %in, i32 [[add]]
; CHECK: load i32, ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @sub_element(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i, i32 %j) {
entry:
  %base = getelementptr i64, ptr addrspace(1) %in, i32 %i
  %shl = shl i32 %j, 3
  %off = add i32 %shl, 4
  %gep = getelementptr i8, ptr addrspace(1) %base, i32 %off
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}

define spir_kernel void @element(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i, i32 %j) {
entry:
  %base = getelementptr i64, ptr addrspace(1) %in, i32 %i
  %shl = shl i32 %j, 3
  %off = add i32 %shl, 8
  %gep = getelementptr i8, ptr addrspace(1) %base, i32 %off
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr addrspace(1) %out, align 4
  ret void
}
