; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics -opaque-pointers
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.outer = type { [2 x %struct.inner] }
%struct.inner = type { <4 x i32>, <4 x i64> }

define dso_local spir_kernel void @fct1(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 64, i1 false)
  ret void
}

define dso_local spir_kernel void @fct2(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 8, i1 false)
  ret void
}

define dso_local spir_kernel void @fct3(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 4, i1 false)
  ret void
}

define dso_local spir_kernel void @fct4(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 3, i1 false)
  ret void
}

define dso_local spir_kernel void @fct5(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %dst, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 64, i1 false)
  %0 = getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1, i32 0
  %1 = getelementptr inbounds %struct.outer, ptr addrspace(1) %src, i32 0, i32 0, i32 1, i32 0
  ret void
}

define dso_local spir_kernel void @fct6(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src) {
entry:
  %0 = getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 16 dereferenceable(16) %0, ptr addrspace(1) noundef align 16 dereferenceable(16) %src, i32 64, i1 false)
  ret void
}

define dso_local spir_kernel void @fct7(ptr addrspace(1) nocapture writeonly align 16 %dst, ptr addrspace(1) nocapture readonly align 16 %src, i32 %n) {
entry:
  %0 = getelementptr %struct.outer, ptr addrspace(1) %src, i32 0, i32 0, i32 %n, i32 1
  %1 = getelementptr %struct.inner, ptr addrspace(1) %dst, i32 0, i32 1
  call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) %1, ptr addrspace(1) %0, i32 16, i1 false)
  ret void
}

declare void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noalias nocapture writeonly %0, ptr addrspace(1) noalias nocapture readonly %1, i32 %2, i1 immarg %3)

; CHECK-DAG: [[inner:%[^ ]+]] = type { <4 x i32>, <4 x i64> }
; CHECK-DAG: [[outer:%[^ ]+]] = type { [2 x [[inner]]] }

; CHECK-LABEL: @fct1
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %src, i32 0
; CHECK:  [[gep_src0:%[^ ]+]] = getelementptr inbounds <4 x i32>, ptr addrspace(1) [[gep_src]], i32 0
; CHECK:  [[gep_dst0:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep_dst]], i32 0
; CHECK:  call void @_Z17spirv.copy_memory(ptr addrspace(1) [[gep_dst0]], ptr addrspace(1) [[gep_src0]], i32 16, i32 0)
; CHECK:  [[gep_src1:%[^ ]+]] = getelementptr inbounds <4 x i32>, ptr addrspace(1) [[gep_src]], i32 1
; CHECK:  [[gep_dst1:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep_dst]], i32 1
; CHECK:  call void @_Z17spirv.copy_memory(ptr addrspace(1) [[gep_dst1]], ptr addrspace(1) [[gep_src1]], i32 16, i32 0)
; CHECK:  [[gep_src2:%[^ ]+]] = getelementptr inbounds <4 x i32>, ptr addrspace(1) [[gep_src]], i32 2
; CHECK:  [[gep_dst2:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep_dst]], i32 2
; CHECK:  call void @_Z17spirv.copy_memory(ptr addrspace(1) [[gep_dst2]], ptr addrspace(1) [[gep_src2]], i32 16, i32 0)
; CHECK:  [[gep_src3:%[^ ]+]] = getelementptr inbounds <4 x i32>, ptr addrspace(1) [[gep_src]], i32 3
; CHECK:  [[gep_dst3:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep_dst]], i32 3
; CHECK:  call void @_Z17spirv.copy_memory(ptr addrspace(1) [[gep_dst3]], ptr addrspace(1) [[gep_src3]], i32 16, i32 0)

; CHECK-LABEL: @fct2
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %src, i32 0
; CHECK:  [[gep_src0:%[^ ]+]] = getelementptr inbounds <2 x i32>, ptr addrspace(1) [[gep_src]], i32 0
; CHECK:  [[gep_dst0:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) [[gep_dst]], i32 0
; CHECK:  call void @_Z17spirv.copy_memory.1(ptr addrspace(1) [[gep_dst0]], ptr addrspace(1) [[gep_src0]], i32 16, i32 0)

; CHECK-LABEL: @fct3
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %src, i32 0
; CHECK:  [[gep_src0:%[^ ]+]] = getelementptr inbounds i32, ptr addrspace(1) [[gep_src]], i32 0
; CHECK:  [[gep_dst0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep_dst]], i32 0
; CHECK:  call void @_Z17spirv.copy_memory.2(ptr addrspace(1) [[gep_dst0]], ptr addrspace(1) [[gep_src0]], i32 16, i32 0)

; CHECK-LABEL: @fct4
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %src, i32 0
; CHECK:  [[gep_src0:%[^ ]+]] = getelementptr inbounds i8, ptr addrspace(1) [[gep_src]], i32 0
; CHECK:  [[gep_dst0:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep_dst]], i32 0
; CHECK:  call void @_Z17spirv.copy_memory.3(ptr addrspace(1) [[gep_dst0]], ptr addrspace(1) [[gep_src0]], i32 16, i32 0)
; CHECK:  [[gep_src1:%[^ ]+]] = getelementptr inbounds i8, ptr addrspace(1) [[gep_src]], i32 1
; CHECK:  [[gep_dst1:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep_dst]], i32 1
; CHECK:  call void @_Z17spirv.copy_memory.3(ptr addrspace(1) [[gep_dst1]], ptr addrspace(1) [[gep_src1]], i32 1, i32 0)
; CHECK:  [[gep_src2:%[^ ]+]] = getelementptr inbounds i8, ptr addrspace(1) [[gep_src]], i32 2
; CHECK:  [[gep_dst2:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep_dst]], i32 2
; CHECK:  call void @_Z17spirv.copy_memory.3(ptr addrspace(1) [[gep_dst2]], ptr addrspace(1) [[gep_src2]], i32 2, i32 0)

; CHECK-LABEL: @fct5
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr inbounds %struct.outer, ptr addrspace(1) %src, i32 0, i32 0, i32 0
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 0
; CHECK:  call void @_Z17spirv.copy_memory.4(ptr addrspace(1) [[gep_dst]], ptr addrspace(1) [[gep_src]], i32 16, i32 0)
; CHECK:  getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1, i32 0
; CHECK:  getelementptr inbounds %struct.outer, ptr addrspace(1) %src, i32 0, i32 0, i32 1, i32 0

; CHECK-LABEL: @fct6
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr inbounds %struct.inner, ptr addrspace(1) %src, i32 0
; CHECK:  [[gep_inner_dst:%[^ ]+]] = getelementptr %struct.inner, ptr addrspace(1) [[gep_dst]], i32 0
; CHECK:  call void @_Z17spirv.copy_memory.5(ptr addrspace(1) [[gep_inner_dst]], ptr addrspace(1) [[gep_src]], i32 16, i32 0)

; CHECK-LABEL: @fct7
; CHECK:  [[gep_src:%[^ ]+]] = getelementptr %struct.outer, ptr addrspace(1) %src, i32 0, i32 0, i32 %n, i32 1
; CHECK:  [[gep_dst:%[^ ]+]] = getelementptr %struct.inner, ptr addrspace(1) %dst, i32 0, i32 1
; CHECK:  [[gep_src0:%[^ ]+]] = getelementptr inbounds <4 x i64>, ptr addrspace(1) [[gep_src]], i32 0, i32 0
; CHECK:  [[gep_dst0:%[^ ]+]] = getelementptr <4 x i64>, ptr addrspace(1) [[gep_dst]], i32 0, i32 0
; CHECK:  call void @_Z17spirv.copy_memory.6(ptr addrspace(1) [[gep_dst0]], ptr addrspace(1) [[gep_src0]], i32 0, i32 0)
; CHECK:  [[gep_src1:%[^ ]+]] = getelementptr inbounds <4 x i64>, ptr addrspace(1) [[gep_src]], i32 0, i32 1
; CHECK:  [[gep_dst1:%[^ ]+]] = getelementptr <4 x i64>, ptr addrspace(1) [[gep_dst]], i32 0, i32 1
; CHECK:  call void @_Z17spirv.copy_memory.6(ptr addrspace(1) [[gep_dst1]], ptr addrspace(1) [[gep_src1]], i32 0, i32 0)
