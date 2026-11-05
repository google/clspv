; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.Pair = type { float, float }
%struct.Vec3 = type { float, float, float }
%struct.Nested = type { %struct.ArrWrap, i32 }
%struct.ArrWrap = type { [4 x float] }
%struct.VecWrap = type { <4 x float>, i32 }
%struct.Mixed = type { float, i64 }

; Zero-index scalar GEP and composite GEP on a helper argument.
; CHECK-LABEL: define dso_local spir_func float @read_pair(
; CHECK: %[[GEP0:[a-zA-Z0-9_.]+]] = getelementptr %struct.Pair, ptr addrspace(1) %p, i32 0, i32 0
; CHECK: %v0 = load float, ptr addrspace(1) %[[GEP0]], align 4
; CHECK: %gep1 = getelementptr %struct.Pair, ptr addrspace(1) %p, i32 0, i32 1
; CHECK: %v1 = load float, ptr addrspace(1) %gep1, align 4

define dso_local spir_func float @read_pair(ptr addrspace(1) %p) {
entry:
  %gep0 = getelementptr float, ptr addrspace(1) %p, i32 0
  %v0 = load float, ptr addrspace(1) %gep0, align 4
  %gep1 = getelementptr %struct.Pair, ptr addrspace(1) %p, i32 0, i32 1
  %v1 = load float, ptr addrspace(1) %gep1, align 4
  %sum = fadd float %v0, %v1
  ret float %sum
}

; Non-zero in-bounds scalar GEP index into an array-like struct, with the
; composite user visited before the scalar user.
; CHECK-LABEL: define dso_local spir_func float @read_array_like_struct_nonzero_idx(
; CHECK: %gep_comp = getelementptr %struct.Vec3, ptr addrspace(1) %p, i32 0, i32 1
; CHECK: %v0 = load float, ptr addrspace(1) %gep_comp, align 4
; CHECK: %[[GEP2:[a-zA-Z0-9_.]+]] = getelementptr %struct.Vec3, ptr addrspace(1) %p, i32 0, i32 2
; CHECK: %v2 = load float, ptr addrspace(1) %[[GEP2]], align 4

define dso_local spir_func float @read_array_like_struct_nonzero_idx(ptr addrspace(1) %p) {
entry:
  %gep_comp = getelementptr %struct.Vec3, ptr addrspace(1) %p, i32 0, i32 1
  %v0 = load float, ptr addrspace(1) %gep_comp, align 4
  %gep_scalar = getelementptr float, ptr addrspace(1) %p, i32 2
  %v2 = load float, ptr addrspace(1) %gep_scalar, align 4
  %sum = fadd float %v0, %v2
  ret float %sum
}

; Multi-level nested composite (%struct.Nested -> %struct.ArrWrap -> [4 x float] -> float)
; with in-bounds non-zero scalar index into the inner array.
; CHECK-LABEL: define dso_local spir_func float @read_nested_array_composite(
; CHECK: %[[GEP_ARR:[a-zA-Z0-9_.]+]] = getelementptr %struct.Nested, ptr addrspace(1) %p, i32 0, i32 0, i32 0, i32 3
; CHECK: %v0 = load float, ptr addrspace(1) %[[GEP_ARR]], align 4
; CHECK: %[[GEP_INNER:[a-zA-Z0-9_.]+]] = getelementptr %struct.Nested, ptr addrspace(1) %p, i32 0, i32 0, i32 0, i32 1
; CHECK: %v1 = load float, ptr addrspace(1) %[[GEP_INNER]], align 4
; CHECK: %gep_outer = getelementptr %struct.Nested, ptr addrspace(1) %p, i32 0, i32 1

define dso_local spir_func float @read_nested_array_composite(ptr addrspace(1) %p) {
entry:
  %gep_scalar = getelementptr float, ptr addrspace(1) %p, i32 3
  %v0 = load float, ptr addrspace(1) %gep_scalar, align 4
  %gep_inner = getelementptr %struct.ArrWrap, ptr addrspace(1) %p, i32 0, i32 0, i32 1
  %v1 = load float, ptr addrspace(1) %gep_inner, align 4
  %gep_outer = getelementptr %struct.Nested, ptr addrspace(1) %p, i32 0, i32 1
  %v2 = load i32, ptr addrspace(1) %gep_outer, align 4
  %v2_f = sitofp i32 %v2 to float
  %sum0 = fadd float %v0, %v1
  %sum1 = fadd float %sum0, %v2_f
  ret float %sum1
}

; Composite containing a FixedVectorType at offset 0 with in-bounds scalar index.
; CHECK-LABEL: define dso_local spir_func float @read_vector_composite(
; CHECK: %[[GEP_VEC:[a-zA-Z0-9_.]+]] = getelementptr %struct.VecWrap, ptr addrspace(1) %p, i32 0, i32 0, i32 2
; CHECK: %v0 = load float, ptr addrspace(1) %[[GEP_VEC]], align 4
; CHECK: %gep_tag = getelementptr %struct.VecWrap, ptr addrspace(1) %p, i32 0, i32 1

define dso_local spir_func float @read_vector_composite(ptr addrspace(1) %p) {
entry:
  %gep_scalar = getelementptr float, ptr addrspace(1) %p, i32 2
  %v0 = load float, ptr addrspace(1) %gep_scalar, align 4
  %gep_tag = getelementptr %struct.VecWrap, ptr addrspace(1) %p, i32 0, i32 1
  %tag = load i32, ptr addrspace(1) %gep_tag, align 4
  %tag_f = sitofp i32 %tag to float
  %sum = fadd float %v0, %tag_f
  ret float %sum
}

; Out-of-bounds scalar GEP index (idx = 5 >= 2) must not infer %struct.Pair as
; the composite pointee type; instead %p falls back to the smaller type (float).
; CHECK-LABEL: define dso_local spir_func float @no_composite_on_oob_idx(
; CHECK: %gep_oob = getelementptr float, ptr addrspace(1) %p, i32 5
; CHECK: %[[GEP1:[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %p, i32 1

define dso_local spir_func float @no_composite_on_oob_idx(ptr addrspace(1) %p) {
entry:
  %gep_oob = getelementptr float, ptr addrspace(1) %p, i32 5
  %v0 = load float, ptr addrspace(1) %gep_oob, align 4
  %gep1 = getelementptr %struct.Pair, ptr addrspace(1) %p, i32 0, i32 1
  %v1 = load float, ptr addrspace(1) %gep1, align 4
  %sum = fadd float %v0, %v1
  ret float %sum
}

; Dynamic scalar GEP index must not infer %struct.Pair as the composite pointee
; type; instead %p falls back to the smaller type (float).
; CHECK-LABEL: define dso_local spir_func float @no_composite_on_dyn_idx(
; CHECK: %gep_dyn = getelementptr float, ptr addrspace(1) %p, i32 %idx
; CHECK: %[[GEP1_DYN:[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %p, i32 1

define dso_local spir_func float @no_composite_on_dyn_idx(ptr addrspace(1) %p, i32 %idx) {
entry:
  %gep_dyn = getelementptr float, ptr addrspace(1) %p, i32 %idx
  %v0 = load float, ptr addrspace(1) %gep_dyn, align 4
  %gep1 = getelementptr %struct.Pair, ptr addrspace(1) %p, i32 0, i32 1
  %v1 = load float, ptr addrspace(1) %gep1, align 4
  %sum = fadd float %v0, %v1
  ret float %sum
}

; Non-zero scalar GEP index into a non-array-like struct (%struct.Mixed) must
; not infer %struct.Mixed as the composite pointee type.
; CHECK-LABEL: define dso_local spir_func i64 @no_composite_on_non_array_like_struct(
; CHECK: %gep_f = getelementptr float, ptr addrspace(1) %p, i32 1
; CHECK-NOT: getelementptr %struct.Mixed, ptr addrspace(1) %p, i32 0, i32 0

define dso_local spir_func i64 @no_composite_on_non_array_like_struct(ptr addrspace(1) %p) {
entry:
  %gep_f = getelementptr float, ptr addrspace(1) %p, i32 1
  %vf = load float, ptr addrspace(1) %gep_f, align 4
  %gep_m = getelementptr %struct.Mixed, ptr addrspace(1) %p, i32 0, i32 1
  %vi = load i64, ptr addrspace(1) %gep_m, align 8
  %vf_i = fptosi float %vf to i64
  %sum = add i64 %vf_i, %vi
  ret i64 %sum
}
