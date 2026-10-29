; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; The 12-byte struct cannot be indexed in units of the 8-byte stored type, so
; the source must be downgraded to i32 (and not i64) to preserve its stride,
; both when storing to and loading from it.

; CHECK-LABEL: @dynamic_index
; CHECK: [[mul:%[^ ]+]] = mul i64 %idx, 3
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %buf, i64 [[mul]]
; CHECK: [[bitcast:%[^ ]+]] = bitcast i64 %val to <2 x i32>
; CHECK: [[ex0:%[^ ]+]] = extractelement <2 x i32> [[bitcast]], i64 0
; CHECK: [[ex1:%[^ ]+]] = extractelement <2 x i32> [[bitcast]], i64 1
; CHECK: [[gep0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i32 0
; CHECK: store i32 [[ex0]], ptr addrspace(1) [[gep0]], align 4
; CHECK: [[gep1:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i64 1
; CHECK: store i32 [[ex1]], ptr addrspace(1) [[gep1]], align 4

; CHECK-LABEL: @constant_index
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %buf, i32 9
; CHECK: [[bitcast:%[^ ]+]] = bitcast i64 %val to <2 x i32>
; CHECK: [[ex0:%[^ ]+]] = extractelement <2 x i32> [[bitcast]], i64 0
; CHECK: [[ex1:%[^ ]+]] = extractelement <2 x i32> [[bitcast]], i64 1
; CHECK: [[gep0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i32 0
; CHECK: store i32 [[ex0]], ptr addrspace(1) [[gep0]], align 4
; CHECK: [[gep1:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i64 1
; CHECK: store i32 [[ex1]], ptr addrspace(1) [[gep1]], align 4

; CHECK-LABEL: @load_dynamic_index
; CHECK: [[mul:%[^ ]+]] = mul i64 %idx, 3
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %buf, i64 [[mul]]
; CHECK: [[gep0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i32 0
; CHECK: [[ld0:%[^ ]+]] = load i32, ptr addrspace(1) [[gep0]], align 4
; CHECK: [[gep1:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i64 1
; CHECK: [[ld1:%[^ ]+]] = load i32, ptr addrspace(1) [[gep1]], align 4
; CHECK: [[ins0:%[^ ]+]] = insertelement <2 x i32> poison, i32 [[ld0]], i32 0
; CHECK: [[ins1:%[^ ]+]] = insertelement <2 x i32> [[ins0]], i32 [[ld1]], i32 1
; CHECK: [[val:%[^ ]+]] = bitcast <2 x i32> [[ins1]] to i64
; CHECK: store i64 [[val]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

%struct.S = type { i32, [5 x i8] }

define spir_kernel void @dynamic_index(ptr addrspace(1) %buf, i64 %idx, i64 %val) {
entry:
  %gep = getelementptr %struct.S, ptr addrspace(1) %buf, i64 %idx
  store i64 %val, ptr addrspace(1) %gep, align 4
  ret void
}

define spir_kernel void @constant_index(ptr addrspace(1) %buf, i64 %val) {
entry:
  %gep = getelementptr %struct.S, ptr addrspace(1) %buf, i64 3
  store i64 %val, ptr addrspace(1) %gep, align 4
  ret void
}

define spir_kernel void @load_dynamic_index(ptr addrspace(1) %buf, ptr addrspace(1) %out, i64 %idx) {
entry:
  %gep = getelementptr %struct.S, ptr addrspace(1) %buf, i64 %idx
  %val = load i64, ptr addrspace(1) %gep, align 4
  %dst = getelementptr i64, ptr addrspace(1) %out, i64 %idx
  store i64 %val, ptr addrspace(1) %dst, align 8
  ret void
}
