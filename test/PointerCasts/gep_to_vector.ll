; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.S = type { i32, <3 x i32> }

; Direct vector alloca: VecIndices is [0], so VecPtr reuses %v without a new GEP.
; CHECK-LABEL: define spir_kernel void @direct_vec_load_store(
; CHECK-NEXT: entry:
; CHECK-NEXT:   %v = alloca <4 x float>, align 16
; CHECK-NEXT:   [[LD0:%[^ ]+]] = load <4 x float>, ptr %v, align 16
; CHECK-NEXT:   [[EXT:%[^ ]+]] = extractelement <4 x float> [[LD0]], i32 %idx
; CHECK-NEXT:   [[ADD:%[^ ]+]] = fadd float [[EXT]], 1.000000e+00
; CHECK-NEXT:   [[LD1:%[^ ]+]] = load <4 x float>, ptr %v, align 16
; CHECK-NEXT:   [[INS:%[^ ]+]] = insertelement <4 x float> [[LD1]], float [[ADD]], i32 %idx
; CHECK-NEXT:   store <4 x float> [[INS]], ptr %v, align 16
; CHECK-NEXT:   ret void
define spir_kernel void @direct_vec_load_store(i32 %idx) {
entry:
  %v = alloca <4 x float>, align 16
  %gep = getelementptr inbounds <4 x float>, ptr %v, i32 0, i32 %idx
  %val = load float, ptr %gep, align 4
  %inc = fadd float %val, 1.000000e+00
  store float %inc, ptr %gep, align 4
  ret void
}

; Array of vectors: creates an inbounds GEP to the vector element.
; CHECK-LABEL: define spir_kernel void @array_of_vec_load_store(
; CHECK-NEXT: entry:
; CHECK-NEXT:   %arr = alloca [3 x <4 x i32>], align 16
; CHECK-NEXT:   [[VEC_GEP:%[^ ]+]] = getelementptr inbounds [3 x <4 x i32>], ptr %arr, i32 0, i32 %i
; CHECK-NEXT:   [[LD0:%[^ ]+]] = load <4 x i32>, ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   [[EXT:%[^ ]+]] = extractelement <4 x i32> [[LD0]], i32 %j
; CHECK-NEXT:   [[LD1:%[^ ]+]] = load <4 x i32>, ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   [[INS:%[^ ]+]] = insertelement <4 x i32> [[LD1]], i32 [[EXT]], i32 %j
; CHECK-NEXT:   store <4 x i32> [[INS]], ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   ret void
define spir_kernel void @array_of_vec_load_store(i32 %i, i32 %j) {
entry:
  %arr = alloca [3 x <4 x i32>], align 16
  %gep = getelementptr inbounds [3 x <4 x i32>], ptr %arr, i32 0, i32 %i, i32 %j
  %val = load i32, ptr %gep, align 4
  store i32 %val, ptr %gep, align 4
  ret void
}

; Struct containing a 3-element vector accessed with a valid constant index.
; CHECK-LABEL: define spir_kernel void @struct_of_vec_const_idx(
; CHECK-NEXT: entry:
; CHECK-NEXT:   %s = alloca %struct.S, align 16
; CHECK-NEXT:   [[VEC_GEP:%[^ ]+]] = getelementptr %struct.S, ptr %s, i32 0, i32 1
; CHECK-NEXT:   [[LD0:%[^ ]+]] = load <3 x i32>, ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   [[INS:%[^ ]+]] = insertelement <3 x i32> [[LD0]], i32 %x, i32 2
; CHECK-NEXT:   store <3 x i32> [[INS]], ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   [[LD1:%[^ ]+]] = load <3 x i32>, ptr [[VEC_GEP]], align 16
; CHECK-NEXT:   [[EXT:%[^ ]+]] = extractelement <3 x i32> [[LD1]], i32 2
; CHECK-NEXT:   store i32 [[EXT]], ptr addrspace(1) %out, align 4
; CHECK-NEXT:   ret void
define spir_kernel void @struct_of_vec_const_idx(i32 %x, ptr addrspace(1) %out) {
entry:
  %s = alloca %struct.S, align 16
  %gep = getelementptr %struct.S, ptr %s, i32 0, i32 1, i32 2
  store i32 %x, ptr %gep, align 4
  %val = load i32, ptr %gep, align 4
  store i32 %val, ptr addrspace(1) %out, align 4
  ret void
}

; Negative test: non-Private address space GEP must not be rewritten by runOnGEPToVector.
; CHECK-LABEL: define spir_kernel void @negative_global_addrspace(
; CHECK:   %gep = getelementptr inbounds <4 x float>, ptr addrspace(1) %p, i32 0, i32 %idx
; CHECK:   load float, ptr addrspace(1) %gep, align 4
define spir_kernel void @negative_global_addrspace(ptr addrspace(1) %p, i32 %idx, ptr addrspace(1) %out) {
entry:
  %gep = getelementptr inbounds <4 x float>, ptr addrspace(1) %p, i32 0, i32 %idx
  %val = load float, ptr addrspace(1) %gep, align 4
  store float %val, ptr addrspace(1) %out, align 4
  ret void
}

; Negative test: out-of-bounds constant element index (>= 4) must not be rewritten.
; CHECK-LABEL: define spir_kernel void @negative_oob_const_idx(
; CHECK:   %gep = getelementptr <4 x float>, ptr %v, i32 0, i32 4
; CHECK:   load float, ptr %gep, align 4
define spir_kernel void @negative_oob_const_idx(ptr addrspace(1) %out) {
entry:
  %v = alloca <4 x float>, align 16
  %gep = getelementptr <4 x float>, ptr %v, i32 0, i32 4
  %val = load float, ptr %gep, align 4
  store float %val, ptr addrspace(1) %out, align 4
  ret void
}

; Negative test: long vectors (> 4 elements) must not be rewritten.
; CHECK-LABEL: define spir_kernel void @negative_long_vector(
; CHECK:   %gep = getelementptr inbounds <8 x float>, ptr %v, i32 0, i32 %idx
; CHECK:   load float, ptr %gep, align 4
define spir_kernel void @negative_long_vector(i32 %idx, ptr addrspace(1) %out) {
entry:
  %v = alloca <8 x float>, align 32
  %gep = getelementptr inbounds <8 x float>, ptr %v, i32 0, i32 %idx
  %val = load float, ptr %gep, align 4
  store float %val, ptr addrspace(1) %out, align 4
  ret void
}

; Negative test: volatile load/store must not be rewritten.
; CHECK-LABEL: define spir_kernel void @negative_volatile(
; CHECK:   %gep = getelementptr inbounds <4 x float>, ptr %v, i32 0, i32 %idx
; CHECK:   load volatile float, ptr %gep, align 4
define spir_kernel void @negative_volatile(i32 %idx, ptr addrspace(1) %out) {
entry:
  %v = alloca <4 x float>, align 16
  %gep = getelementptr inbounds <4 x float>, ptr %v, i32 0, i32 %idx
  %val = load volatile float, ptr %gep, align 4
  store float %val, ptr addrspace(1) %out, align 4
  ret void
}
