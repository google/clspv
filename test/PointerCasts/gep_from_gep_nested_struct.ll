; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.Inner = type { i32, i32 }
%struct.Middle = type { %struct.Inner, i32 }
%struct.Outer = type { %struct.Middle }
%struct.DeepOuter = type { %struct.Outer, i32 }
%struct.TwoMiddles = type { %struct.Middle, %struct.Middle, i32 }
%struct.ArrOuter = type { [2 x %struct.Inner], i32 }

; Offset (2 * i32 = 8 bytes) exceeds %struct.Inner (8 bytes) and folds into
; field 1 of the enclosing %struct.Middle.
; CHECK-LABEL: define spir_kernel void @pop_one_enclosing_struct(
; CHECK: %[[GEP1:[a-zA-Z0-9_.]+]] = getelementptr %struct.Outer, ptr addrspace(1) %buf, i32 %idx, i32 0, i32 1
; CHECK: store i32 42, ptr addrspace(1) %[[GEP1]], align 4

define spir_kernel void @pop_one_enclosing_struct(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %base = getelementptr %struct.Outer, ptr addrspace(1) %buf, i32 %idx, i32 0
  %gep = getelementptr i32, ptr addrspace(1) %base, i32 2
  store i32 42, ptr addrspace(1) %gep, align 4
  ret void
}

; Offset (3 * i32 = 12 bytes) exceeds %struct.Inner (8 bytes), %struct.Middle
; (12 bytes), and %struct.Outer (12 bytes), popping two enclosing struct levels
; to fold into field 1 of %struct.DeepOuter.
; CHECK-LABEL: define spir_kernel void @pop_two_enclosing_structs(
; CHECK: %[[GEP2:[a-zA-Z0-9_.]+]] = getelementptr %struct.DeepOuter, ptr addrspace(1) %buf, i32 %idx, i32 1
; CHECK: store i32 99, ptr addrspace(1) %[[GEP2]], align 4

define spir_kernel void @pop_two_enclosing_structs(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %base = getelementptr %struct.DeepOuter, ptr addrspace(1) %buf, i32 %idx, i32 0, i32 0
  %gep = getelementptr i32, ptr addrspace(1) %base, i32 3
  store i32 99, ptr addrspace(1) %gep, align 4
  ret void
}

; Non-zero field index on an enclosing struct (field 1 of %struct.TwoMiddles,
; at byte offset 12) combined with offset 3 * i32 (12 bytes) folds to field 2
; (at byte offset 24) of %struct.TwoMiddles.
; CHECK-LABEL: define spir_kernel void @nonzero_intermediate_struct_field(
; CHECK: %[[GEP3:[a-zA-Z0-9_.]+]] = getelementptr %struct.TwoMiddles, ptr addrspace(1) %buf, i32 %idx, i32 2
; CHECK: store i32 7, ptr addrspace(1) %[[GEP3]], align 4

define spir_kernel void @nonzero_intermediate_struct_field(ptr addrspace(1) %buf, i32 %idx) {
entry:
  %base = getelementptr %struct.TwoMiddles, ptr addrspace(1) %buf, i32 %idx, i32 1, i32 0
  %gep = getelementptr i32, ptr addrspace(1) %base, i32 3
  store i32 7, ptr addrspace(1) %gep, align 4
  ret void
}

; When popping enclosing indices reaches a non-struct type ([2 x %struct.Inner]),
; the struct-popping loop stops cleanly and falls back to private/local offset
; reconstruction into the second array element.
; CHECK-LABEL: define spir_func void @stop_at_enclosing_array(
; CHECK: %[[GEP4:[a-zA-Z0-9_.]+]] = getelementptr %struct.ArrOuter, ptr %buf, i32 0, i32 0, i32 1, i32 0
; CHECK: store i32 13, ptr %[[GEP4]], align 4

define spir_func void @stop_at_enclosing_array(ptr %buf) {
entry:
  %base = getelementptr %struct.ArrOuter, ptr %buf, i32 0, i32 0, i32 0, i32 0
  %gep = getelementptr i32, ptr %base, i32 2
  store i32 13, ptr %gep, align 4
  ret void
}
