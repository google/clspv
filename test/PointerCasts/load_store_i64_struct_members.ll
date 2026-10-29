; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; The i64 load and store access the first two members of a struct which size
; is not a multiple of the size of i64. The struct is downgraded to i32, which
; keeps its 12-byte stride, and the i64 accesses are split into two i32 ones.

; CHECK-LABEL: @struct12
; CHECK: [[in_idx:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[in_gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 [[in_idx]]
; CHECK: [[gep_a:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[in_gep]], i32 0
; CHECK: [[a:%[^ ]+]] = load i32, ptr addrspace(1) [[gep_a]], align 4
; CHECK: [[gep_b:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[in_gep]], i32 1
; CHECK: [[b:%[^ ]+]] = load i32, ptr addrspace(1) [[gep_b]], align 4
; CHECK: [[ins_a:%[^ ]+]] = insertelement <2 x i32> poison, i32 [[a]], i32 0
; CHECK: [[ins_b:%[^ ]+]] = insertelement <2 x i32> [[ins_a]], i32 [[b]], i32 1
; CHECK: [[val:%[^ ]+]] = bitcast <2 x i32> [[ins_b]] to i64
; CHECK: [[in_c_mul:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[in_c_idx:%[^ ]+]] = add i32 [[in_c_mul]], 2
; CHECK: [[gep_c:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 [[in_c_idx]]
; CHECK: %c = load i32, ptr addrspace(1) [[gep_c]], align 4
; CHECK: [[add:%[^ ]+]] = add i64 [[val]], 1
; CHECK: [[out_idx:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[out_gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %out, i32 [[out_idx]]
; CHECK: [[split:%[^ ]+]] = bitcast i64 [[add]] to <2 x i32>
; CHECK: [[lo:%[^ ]+]] = extractelement <2 x i32> [[split]], i64 0
; CHECK: [[hi:%[^ ]+]] = extractelement <2 x i32> [[split]], i64 1
; CHECK: [[gep_a:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[out_gep]], i32 0
; CHECK: store i32 [[lo]], ptr addrspace(1) [[gep_a]], align 4
; CHECK: [[gep_b:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[out_gep]], i32 1
; CHECK: store i32 [[hi]], ptr addrspace(1) [[gep_b]], align 4
; CHECK: [[out_c_mul:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[out_c_idx:%[^ ]+]] = add i32 [[out_c_mul]], 2
; CHECK: [[gep_c:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %out, i32 [[out_c_idx]]
; CHECK: store i32 %c, ptr addrspace(1) [[gep_c]], align 4

; The i64 store covers an i32 and a float member. The struct must not be
; downgraded to i64, which would lose the offset of the struct and of its third
; member.

; CHECK-LABEL: @mixed
; CHECK: [[idx:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[dst:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %out, i32 [[idx]]
; CHECK: [[split:%[^ ]+]] = bitcast i64 %ab to <2 x i32>
; CHECK: [[lo:%[^ ]+]] = extractelement <2 x i32> [[split]], i64 0
; CHECK: [[hi:%[^ ]+]] = extractelement <2 x i32> [[split]], i64 1
; CHECK: [[gep_a:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[dst]], i32 0
; CHECK: store i32 [[lo]], ptr addrspace(1) [[gep_a]], align 4
; CHECK: [[gep_b:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[dst]], i32 1
; CHECK: store i32 [[hi]], ptr addrspace(1) [[gep_b]], align 4
; CHECK: [[c_mul:%[^ ]+]] = mul i32 %i, 3
; CHECK: [[c_idx:%[^ ]+]] = add i32 [[c_mul]], 2
; CHECK: [[gep_c:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %out, i32 [[c_idx]]
; CHECK: store i32 %c, ptr addrspace(1) [[gep_c]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.T12 = type { i32, i32, i32 }
%struct.M = type { i32, float, i32 }

define spir_kernel void @struct12(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i) {
entry:
  %src = getelementptr %struct.T12, ptr addrspace(1) %in, i32 %i
  %ab = load i64, ptr addrspace(1) %src, align 4
  %src_c = getelementptr %struct.T12, ptr addrspace(1) %in, i32 %i, i32 2
  %c = load i32, ptr addrspace(1) %src_c, align 4
  %add = add i64 %ab, 1
  %dst = getelementptr %struct.T12, ptr addrspace(1) %out, i32 %i
  store i64 %add, ptr addrspace(1) %dst, align 4
  %dst_c = getelementptr %struct.T12, ptr addrspace(1) %out, i32 %i, i32 2
  store i32 %c, ptr addrspace(1) %dst_c, align 4
  ret void
}

define spir_kernel void @mixed(ptr addrspace(1) %out, i32 %i, i64 %ab, i32 %c) {
entry:
  %dst = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i
  store i64 %ab, ptr addrspace(1) %dst, align 4
  %dst_c = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i, i32 2
  store i32 %c, ptr addrspace(1) %dst_c, align 4
  ret void
}
