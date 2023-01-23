; RUN: clspv-opt %s -o %t --passes=cluster-constants
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@mem0 = addrspace(2) constant [3 x i8] zeroinitializer, align 1
@mem8 = addrspace(2) constant [3 x [8 x i8]] zeroinitializer, align 8

define spir_kernel void @foo() {
entry:
  %0 = getelementptr [3 x i8], ptr addrspace(2) @mem0, i32 0
  %1 = getelementptr [3 x [8 x i8]], ptr addrspace(2) @mem8, i32 0
  ret void
}

; CHECK: [[clustered_constants:@[^ ]+]] = internal addrspace(2) constant { [3 x i8], [5 x i8], [3 x [8 x i8]] } zeroinitializer, align 8

; CHECK: [[mem0:%[^ ]+]] = getelementptr inbounds { [3 x i8], [5 x i8], [3 x [8 x i8]] }, ptr addrspace(2) [[clustered_constants]], i32 0, i32 0
; CHECK: getelementptr [3 x i8], ptr addrspace(2) [[mem0]], i32 0

; CHECK: [[mem8:%[^ ]+]] = getelementptr inbounds { [3 x i8], [5 x i8], [3 x [8 x i8]] }, ptr addrspace(2) [[clustered_constants]], i32 0, i32 2
; CHECK: getelementptr [3 x [8 x i8]], ptr addrspace(2) [[mem8]], i32 0
