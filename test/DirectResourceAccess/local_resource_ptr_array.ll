; RUN: clspv-opt %s -o %t.ll --passes=direct-resource-access
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x float] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x float] })
declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x float] })
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

; Dynamic index into a 2-element resource pointer array builds a select and
; erases the dead alloca, stores, and GEPs.
; CHECK-LABEL: define dso_local spir_kernel void @dynamic_index(
; CHECK-NOT: alloca [2 x ptr addrspace(1)]
; CHECK: %[[CMP:[a-zA-Z0-9_.]+]] = icmp eq i32 %idx, 1
; CHECK: %[[SEL:[a-zA-Z0-9_.]+]] = select i1 %[[CMP]], ptr addrspace(1) %res2, ptr addrspace(1) %res1
; CHECK: %[[GEP:[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) %[[SEL]], i32 %elem
; CHECK: load float, ptr addrspace(1) %[[GEP]], align 4

define dso_local spir_kernel void @dynamic_index(ptr addrspace(1) %out, ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %idx, i32 %elem) {
entry:
  %res0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %res1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %res2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %arrs = alloca [2 x ptr addrspace(1)], align 4
  %s0 = getelementptr [2 x ptr addrspace(1)], ptr %arrs, i32 0, i32 0
  store ptr addrspace(1) %res1, ptr %s0, align 4
  %s1 = getelementptr [2 x ptr addrspace(1)], ptr %arrs, i32 0, i32 1
  store ptr addrspace(1) %res2, ptr %s1, align 4
  %slot = getelementptr [2 x ptr addrspace(1)], ptr %arrs, i32 0, i32 %idx
  %buf = load ptr addrspace(1), ptr %slot, align 4
  %gep = getelementptr float, ptr addrspace(1) %buf, i32 %elem
  %val = load float, ptr addrspace(1) %gep, align 4
  store float %val, ptr addrspace(1) %res0, align 4
  ret void
}

; Direct store/load at base pointer (index 0) and constant-index GEP load fold
; directly to the underlying resource pointers without a select.
; CHECK-LABEL: define dso_local spir_kernel void @const_and_base_index(
; CHECK-NOT: alloca [2 x ptr addrspace(1)]
; CHECK-NOT: select
; CHECK: %gep0 = getelementptr float, ptr addrspace(1) %res1, i32 %elem
; CHECK: %v0 = load float, ptr addrspace(1) %gep0, align 4
; CHECK: %gep1 = getelementptr float, ptr addrspace(1) %res2, i32 %elem
; CHECK: %v1 = load float, ptr addrspace(1) %gep1, align 4

define dso_local spir_kernel void @const_and_base_index(ptr addrspace(1) %out, ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %elem) {
entry:
  %res0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %res1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %res2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %arrs = alloca [2 x ptr addrspace(1)], align 4
  store ptr addrspace(1) %res1, ptr %arrs, align 4
  %s1 = getelementptr [2 x ptr addrspace(1)], ptr %arrs, i32 0, i32 1
  store ptr addrspace(1) %res2, ptr %s1, align 4
  %buf0 = load ptr addrspace(1), ptr %arrs, align 4
  %gep0 = getelementptr float, ptr addrspace(1) %buf0, i32 %elem
  %v0 = load float, ptr addrspace(1) %gep0, align 4
  %buf1 = load ptr addrspace(1), ptr %s1, align 4
  %gep1 = getelementptr float, ptr addrspace(1) %buf1, i32 %elem
  %v1 = load float, ptr addrspace(1) %gep1, align 4
  %sum = fadd float %v0, %v1
  store float %sum, ptr addrspace(1) %res0, align 4
  ret void
}

; Unwritten array slots default to null, multi-element dynamic indexing chains
; selects, and lifetime intrinsics on the dead alloca are cleaned up.
; CHECK-LABEL: define dso_local spir_kernel void @unwritten_slot_and_lifetime(
; CHECK-NOT: alloca [3 x ptr addrspace(1)]
; CHECK-NOT: llvm.lifetime
; CHECK: %[[CMP1:[a-zA-Z0-9_.]+]] = icmp eq i32 %idx, 1
; CHECK: %[[SEL1:[a-zA-Z0-9_.]+]] = select i1 %[[CMP1]], ptr addrspace(1) null, ptr addrspace(1) %res1
; CHECK: %[[CMP2:[a-zA-Z0-9_.]+]] = icmp eq i32 %idx, 2
; CHECK: %[[SEL2:[a-zA-Z0-9_.]+]] = select i1 %[[CMP2]], ptr addrspace(1) %res2, ptr addrspace(1) %[[SEL1]]
; CHECK: %gep = getelementptr float, ptr addrspace(1) %[[SEL2]], i32 %elem

define dso_local spir_kernel void @unwritten_slot_and_lifetime(ptr addrspace(1) %out, ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %idx, i32 %elem) {
entry:
  %res0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %res1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %res2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %arrs = alloca [3 x ptr addrspace(1)], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr %arrs)
  %s0 = getelementptr [3 x ptr addrspace(1)], ptr %arrs, i32 0, i32 0
  store ptr addrspace(1) %res1, ptr %s0, align 4
  %s2 = getelementptr [3 x ptr addrspace(1)], ptr %arrs, i32 0, i32 2
  store ptr addrspace(1) %res2, ptr %s2, align 4
  %slot = getelementptr [3 x ptr addrspace(1)], ptr %arrs, i32 0, i32 %idx
  %buf = load ptr addrspace(1), ptr %slot, align 4
  %gep = getelementptr float, ptr addrspace(1) %buf, i32 %elem
  %val = load float, ptr addrspace(1) %gep, align 4
  store float %val, ptr addrspace(1) %res0, align 4
  call void @llvm.lifetime.end.p0(i64 12, ptr %arrs)
  ret void
}

; If the alloca address itself is stored as a value, loads from it are still
; replaced, but the alloca and its stores are not erased.
; CHECK-LABEL: define dso_local spir_kernel void @escaped_alloca_preserved(
; CHECK: %arrs = alloca [2 x ptr addrspace(1)], align 4
; CHECK: store ptr addrspace(1) %res1, ptr %s0, align 4
; CHECK: store ptr %arrs, ptr %escape_slot, align 4
; CHECK: %gep = getelementptr float, ptr addrspace(1) %res1, i32 %elem

define dso_local spir_kernel void @escaped_alloca_preserved(ptr addrspace(1) %out, ptr addrspace(1) %a, i32 %elem) {
entry:
  %res0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %res1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x float] } zeroinitializer)
  %arrs = alloca [2 x ptr addrspace(1)], align 4
  %escape_slot = alloca ptr, align 4
  %s0 = getelementptr [2 x ptr addrspace(1)], ptr %arrs, i32 0, i32 0
  store ptr addrspace(1) %res1, ptr %s0, align 4
  store ptr %arrs, ptr %escape_slot, align 4
  %buf = load ptr addrspace(1), ptr %s0, align 4
  %gep = getelementptr float, ptr addrspace(1) %buf, i32 %elem
  %val = load float, ptr addrspace(1) %gep, align 4
  store float %val, ptr addrspace(1) %res0, align 4
  ret void
}
