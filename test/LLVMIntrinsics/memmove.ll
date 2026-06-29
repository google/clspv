; RUN: clspv --physical-storage-buffers --arch=spir64 -x=ir %s -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

define dso_local spir_kernel void @static_global_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
  tail call void @llvm.memmove.p1.p1.i64(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 64, i1 false)
  ret void
}

define dso_local spir_kernel void @large_static_global_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
  tail call void @llvm.memmove.p1.p1.i64(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 512, i1 false)
  ret void
}

define dso_local spir_kernel void @dynamic_global_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 %len) {
  tail call void @llvm.memmove.p1.p1.i64(ptr addrspace(1) %dst, ptr addrspace(1) %src, i64 %len, i1 false)
  ret void
}

define dso_local spir_kernel void @static_private_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src) {
  %a = alloca [4 x i32], align 16
  call void @llvm.memcpy.p0.p1.i64(ptr align 16 %a, ptr addrspace(1) %src, i64 16, i1 false)
  %gep = getelementptr inbounds i8, ptr %a, i64 4
  call void @llvm.memmove.p0.p0.i64(ptr align 16 %a, ptr align 4 %gep, i64 12, i1 false)
  call void @llvm.memcpy.p1.p0.i64(ptr addrspace(1) %dst, ptr align 4 %gep, i64 16, i1 false)
  ret void
}

define dso_local spir_kernel void @static_local_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src, ptr addrspace(3) %scratch) {
  call void @llvm.memcpy.p3.p1.i64(ptr addrspace(3) %scratch, ptr addrspace(1) %src, i64 16, i1 false)
  %gep = getelementptr inbounds i8, ptr addrspace(3) %scratch, i64 4
  call void @llvm.memmove.p3.p3.i64(ptr addrspace(3) %scratch, ptr addrspace(3) %scratch, i64 12, i1 false)
  call void @llvm.memcpy.p1.p3.i64(ptr addrspace(1) %dst, ptr addrspace(3) %scratch, i64 16, i1 false)
  ret void
}

define dso_local spir_kernel void @dynamic_local_ptr(ptr addrspace(1) %dst, ptr addrspace(1) %src, ptr addrspace(3) %scratch, i64 %len) {
  call void @llvm.memcpy.p3.p1.i64(ptr addrspace(3) %scratch, ptr addrspace(1) %src, i64 16, i1 false)
  %gep = getelementptr inbounds i8, ptr addrspace(3) %scratch, i64 4
  call void @llvm.memmove.p3.p3.i64(ptr addrspace(3) %scratch, ptr addrspace(3) %scratch, i64 %len, i1 false)
  call void @llvm.memcpy.p1.p3.i64(ptr addrspace(1) %dst, ptr addrspace(3) %scratch, i64 16, i1 false)
  ret void
}

declare void @llvm.memmove.p1.p1.i64(ptr addrspace(1), ptr addrspace(1), i64, i1)

declare void @llvm.memmove.p3.p3.i64(ptr addrspace(3), ptr addrspace(3), i64, i1)

declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)

declare void @llvm.memcpy.p0.p1.i64(ptr, ptr addrspace(1), i64, i1)

declare void @llvm.memcpy.p1.p0.i64(ptr addrspace(1), ptr, i64, i1)
