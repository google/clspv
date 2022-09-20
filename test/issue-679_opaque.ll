; RUN: clspv-opt --passes=three-element-vector-lowering %s -o %t --opaque-pointers
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test1(ptr %in, i32 %n) {
entry:
    %gep = getelementptr <3 x float>, ptr %in, i32 %n
    %alloca = alloca float
    store ptr %alloca, ptr %gep, align 4
    ret void
}

; CHECK: define spir_kernel void @test1(ptr %in, i32 %n) {
; CHECK: %gep = getelementptr inbounds <4 x float>, ptr %in, i32 %n
; CHECK: %alloca = alloca float, align 4
; CHECK: store ptr %alloca, ptr %gep, align 4

define void @test2(ptr addrspace(1) %data) {
entry:
  %gep1 = getelementptr <3 x i32>, ptr addrspace(1) %data, i32 0, i32 2
  %gep2 = getelementptr i32, ptr addrspace(1) %gep1, i32 3
  store i32 0, ptr addrspace(1) %gep2
  ret void
}

; CHECK: define void @test2(ptr addrspace(1) %data) {
; CHECK: %gep1 = getelementptr inbounds <4 x i32>, ptr addrspace(1) %data, i32 0, i32 2
; CHECK: %gep2 = getelementptr i32, ptr addrspace(1) %gep1, i32 3
; CHECK: store i32 0, ptr addrspace(1) %gep2

define i32 @test3(ptr addrspace(1) %data) {
entry:
  %gep1 = getelementptr <3 x i32>, ptr addrspace(1) %data, i32 0, i32 2
  %gep2 = getelementptr i32, ptr addrspace(1) %gep1, i32 3
  %ld = load i32, ptr addrspace(1) %gep2
  ret i32 %ld
}

; CHECK: define i32 @test3(ptr addrspace(1) %data) {
; CHECK: %gep1 = getelementptr inbounds <4 x i32>, ptr addrspace(1) %data, i32 0, i32 2
; CHECK: %gep2 = getelementptr i32, ptr addrspace(1) %gep1, i32 3
; CHECK: %ld = load i32, ptr addrspace(1) %gep2

define void @test4() {
entry:
  %data = alloca <3 x i32>
  %gep1 = getelementptr <3 x i32>, ptr %data, i32 0, i32 2
  %gep2 = getelementptr i32, ptr %gep1, i32 3
  store i32 0, ptr %gep2
  ret void
}

; CHECK: define void @test4() {
; CHECK: %data = alloca <4 x i32>
; CHECK: %gep1 = getelementptr inbounds <4 x i32>, ptr %data, i32 0, i32 2
; CHECK: %gep2 = getelementptr i32, ptr %gep1, i32 3
; CHECK: store i32 0, ptr %gep2

define i32 @test5() {
entry:
  %data = alloca <3 x i32>
  %gep1 = getelementptr <3 x i32>, ptr %data, i32 0, i32 2
  %gep2 = getelementptr i32, ptr %gep1, i32 3
  %ld = load i32, ptr %gep2
  ret i32 %ld
}

; CHECK: define i32 @test5() {
; CHECK: %data = alloca <4 x i32>
; CHECK: %gep1 = getelementptr inbounds <4 x i32>, ptr %data, i32 0, i32 2
; CHECK: %gep2 = getelementptr i32, ptr %gep1, i32 3
; CHECK: %ld = load i32, ptr %gep2