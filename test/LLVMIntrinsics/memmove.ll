; RUN: clspv -x=ir %s --spv-version=1.4 -o %t.spv
; RUN: spirv-val %t.spv --target-env spv1.4
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

define dso_local spir_kernel void @fct1(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
  tail call void @llvm.memmove.p1.p1.i32(ptr addrspace(1) %dst, ptr addrspace(1) %src, i32 64, i1 false)
  ret void
}
define dso_local spir_kernel void @fct2(ptr addrspace(1) %dst, ptr addrspace(1) %src, i32 %len) {
  tail call void @llvm.memmove.p1.p1.i32(ptr addrspace(1) %dst, ptr addrspace(1) %src, i32 %len, i1 false)
  ret void
}

; CHECK: [[fct1_dst_arg:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} StorageBuffer
; CHECK: [[fct1_src_arg:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} StorageBuffer
; CHECK: [[fct1_arr_var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Function
; CHECK: [[src_gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[fct1_src_arg]]
; CHECK: [[src_load:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[src_gep]]
; CHECK: [[src_copy:%[a-zA-Z0-9_]+]] = OpCopyLogical {{.*}} [[src_load]]
; CHECK: [[arr_gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[fct1_arr_var]]
; CHECK: OpStore [[arr_gep1]] [[src_copy]]
; CHECK: [[arr_gep2:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[fct1_arr_var]]
; CHECK: [[arr_load:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[arr_gep2]]
; CHECK: [[dst_gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[fct1_dst_arg]]
; CHECK: [[arr_copy:%[a-zA-Z0-9_]+]] = OpCopyLogical {{.*}} [[arr_load]]
; CHECK: OpStore [[dst_gep]] [[arr_copy]]
; CHECK: OpReturn

declare void @llvm.memmove.p1.p1.i32(ptr addrspace(1), ptr addrspace(1), i32, i1)
