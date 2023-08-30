; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.outer = type { [2 x %struct.inner] }
%struct.inner = type { <4 x i32>, <4 x i64> }

define dso_local spir_kernel void @fct1(ptr addrspace(1) %dst) {
entry:
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 64, i1 false)
  ret void
}

define dso_local spir_kernel void @fct2(ptr addrspace(1) %dst) {
entry:
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 8, i1 false)
  ret void
}

define dso_local spir_kernel void @fct3(ptr addrspace(1) %dst) {
entry:
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 4, i1 false)
  ret void
}

define dso_local spir_kernel void @fct4(ptr addrspace(1) %dst) {
entry:
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 3, i1 false)
  ret void
}

define dso_local spir_kernel void @fct5(ptr addrspace(1) %dst) {
entry:
  tail call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 64, i1 false)
  %0 = getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1, i32 0
  ret void
}

define dso_local spir_kernel void @fct6() {
entry:
  %0 = alloca [16 x i32], align 4
  tail call void @llvm.memset.p0.i32(ptr %0, i8 0, i32 16, i1 false)
  ret void
}

declare void @llvm.memset.p1.i32(ptr addrspace(1), i8, i32, i1)
declare void @llvm.memset.p0.i32(ptr, i8, i32, i1)

; CHECK-LABEL: @fct1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep0:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store <4 x i32> zeroinitializer, ptr addrspace(1) [[gep0]]
; CHECK:  [[gep1:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep]], i32 1
; CHECK:  store <4 x i32> zeroinitializer, ptr addrspace(1) [[gep1]]
; CHECK:  [[gep2:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep]], i32 2
; CHECK:  store <4 x i32> zeroinitializer, ptr addrspace(1) [[gep2]]
; CHECK:  [[gep3:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) [[gep]], i32 3
; CHECK:  store <4 x i32> zeroinitializer, ptr addrspace(1) [[gep3]]

; CHECK-LABEL: @fct2
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep0:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store <2 x i32> zeroinitializer, ptr addrspace(1) [[gep0]]

; CHECK-LABEL: @fct3
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store i32 0, ptr addrspace(1) [[gep0]]

; CHECK-LABEL: @fct4
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %dst, i32 0
; CHECK:  [[gep0:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store i8 0, ptr addrspace(1) [[gep0]]
; CHECK:  [[gep1:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 1
; CHECK:  store i8 0, ptr addrspace(1) [[gep1]]
; CHECK:  [[gep2:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 2
; CHECK:  store i8 0, ptr addrspace(1) [[gep2]]

; CHECK-LABEL: @fct5
; CHECK:  [[gep:%[^ ]+]] = getelementptr %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 0
; CHECK:  store %struct.inner zeroinitializer, ptr addrspace(1) [[gep]], align 32
; CHECK:  getelementptr inbounds %struct.outer, ptr addrspace(1) %dst, i32 0, i32 0, i32 1, i32 0

; CHECK-LABEL: @fct6
; CHECK:  [[alloca:%[^ ]+]] = alloca [16 x i32], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr [16 x i32], ptr [[alloca]], i32 0, i32 0
; CHECK:  store i32 0, ptr [[gep]], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr [16 x i32], ptr [[alloca]], i32 0, i32 1
; CHECK:  store i32 0, ptr [[gep]], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr [16 x i32], ptr [[alloca]], i32 0, i32 2
; CHECK:  store i32 0, ptr [[gep]], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr [16 x i32], ptr [[alloca]], i32 0, i32 3
; CHECK:  store i32 0, ptr [[gep]], align 4
