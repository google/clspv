; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LABEL: define void @test1() {
; CHECK: entry:
; CHECK:   %0 = add i32 0, 4
; CHECK:   %gep = getelementptr i64, ptr null, i32 %0
; CHECK:   ret void
; CHECK: }

define void @test1() {
entry:
  %0 = add i32 0, 4
  %cast = bitcast i32 %0 to i32
  %gep = getelementptr i64, ptr bitcast (ptr null to ptr), i32 %0
  ret void
}

; CHECK-LABEL: define void @test2() {
; CHECK: entry:
; CHECK:   %gep = getelementptr i64, ptr null, i32 0
; CHECK:   ret void
; CHECK: }

define void @test2() {
entry:
  %cast1 = bitcast ptr bitcast ( ptr null to ptr ) to ptr
  %cast2 = bitcast ptr %cast1 to ptr
  %gep = getelementptr i64, ptr %cast2, i32 0
  ret void
}

; CHECK-LABEL: define void @test3() {
; CHECK: entry:
; CHECK:   %gep = getelementptr i64, ptr null, i32 0
; CHECK:   ret void
; CHECK: }

define void @test3() {
entry:
  %cast1 = bitcast ptr bitcast ( ptr null to ptr ) to ptr
  %cast2 = bitcast ptr %cast1 to ptr
  %cast3 = bitcast ptr %cast2 to ptr
  %gep = getelementptr i64, ptr %cast3, i32 0
  ret void
}

; CHECK-LABEL: define void @test4(ptr %in, ptr %out) {
; CHECK: entry:
; CHECK:   %gep = getelementptr i32, ptr %in, i32 0
; CHECK:   %val = load i32, ptr %gep, align 4
; CHECK:   store i32 %val, ptr %out, align 4
; CHECK:   ret void
; CHECK: }

define void @test4(ptr %in, ptr %out) {
entry:
  %gep = getelementptr i32, ptr %in, i32 0     
  %cast = bitcast ptr %gep to ptr
  %val = load i32, ptr %cast
  store i32 %val, ptr %out
  ret void
}

; CHECK-LABEL: define void @test5(ptr %in) {
; CHECK: entry:
; CHECK:   %0 = getelementptr i32, ptr %in, i32 2
; CHECK:   ret void
; CHECK: }

define void @test5(ptr %in) {
entry:
  %gep1 = getelementptr i32, ptr %in, i32 1
  %gep2 = getelementptr i32, ptr %gep1, i32 1   
  ret void
}

; CHECK-LABEL: define void @test7(ptr addrspace(1) %in) {
; CHECK: entry:
; CHECK:   getelementptr float, ptr addrspace(1) %in, i32 2
; CHECK-NEXT: ret void
; CHECK: }

define void @test7(ptr addrspace(1) %in) {
entry:
  %gep1 = getelementptr float, ptr addrspace(1) %in, i32 1
  %gep2 = getelementptr i32, ptr addrspace(1) %gep1, i32 1
  ret void
}
