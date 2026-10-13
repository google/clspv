; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: @use_src(
; CHECK: [[gep_src:%[^ ]+]] = getelementptr %struct.IT, ptr addrspace(1) %src, i32 0, i32 1, i32 0
; CHECK: call void @llvm.memcpy.p0.p1.i32(ptr align 4 %m, ptr addrspace(1) align 4 [[gep_src]], i32 64, i1 false)

; CHECK-LABEL: @use_dst(
; CHECK: [[gep_dst:%[^ ]+]] = getelementptr %struct.IT, ptr addrspace(1) %dst, i32 0, i32 1, i32 0
; CHECK: call void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) align 4 [[gep_dst]], ptr align 4 %m, i32 64, i1 false)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.IT = type { float, %struct.Transform }
%struct.Transform = type { %struct.Matrix4x4 }
%struct.Matrix4x4 = type { [4 x [4 x float]] }

declare void @llvm.memcpy.p0.p1.i32(ptr noalias writeonly captures(none), ptr addrspace(1) noalias readonly captures(none), i32, i1 immarg)
declare void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) noalias writeonly captures(none), ptr noalias readonly captures(none), i32, i1 immarg)

define spir_kernel void @use_src(ptr addrspace(1) noalias align 4 %src, ptr addrspace(1) align 4 %out) {
entry:
  %m = alloca %struct.Matrix4x4, align 4
  %start = getelementptr inbounds nuw %struct.IT, ptr addrspace(1) %src, i32 0, i32 1
  call void @llvm.memcpy.p0.p1.i32(ptr align 4 %m, ptr addrspace(1) align 4 %start, i32 64, i1 false)
  %0 = load float, ptr %m, align 4
  store float %0, ptr addrspace(1) %out, align 4
  ret void
}

define spir_kernel void @use_dst(ptr addrspace(1) noalias align 4 %dst, ptr addrspace(1) align 4 %in) {
entry:
  %m = alloca %struct.Matrix4x4, align 4
  %0 = load float, ptr addrspace(1) %in, align 4
  store float %0, ptr %m, align 4
  %start = getelementptr inbounds nuw %struct.IT, ptr addrspace(1) %dst, i32 0, i32 1
  call void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) align 4 %start, ptr align 4 %m, i32 64, i1 false)
  ret void
}
