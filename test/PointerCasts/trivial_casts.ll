; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LABEL: define void @test1() {
; CHECK: entry:
; CHECK:   %0 = add i32 0, 4
; CHECK:   %gep = getelementptr i32, i32* null, i32 %0
; CHECK:   ret void
; CHECK: }

define void @test1() {
entry:
  %0 = add i32 0, 4
  %cast = bitcast i32 %0 to i32
  %gep = getelementptr i32, i32* bitcast (float* null to i32*), i32 %0
  ret void
}

; CHECK-LABEL: define void @test2() {
; CHECK: entry:
; CHECK:   %gep = getelementptr i64, i64* null, i32 250
; CHECK:   ret void
; CHECK: }

define void @test2() {
entry:
  %cast1 = bitcast i32 bitcast ( i32 250 to i32 ) to float
  %cast2 = bitcast float %cast1 to i32
  %gep = getelementptr i64, i64* null, i32 %cast2
  ret void
}

; CHECK-LABEL: define void @test3() {
; CHECK: entry:
; CHECK:   %0 = bitcast float 0x371F400000000000 to i32
; CHECK:   %gep = getelementptr i64, i64* null, i32 %0
; CHECK:   ret void
; CHECK: }

define void @test3() {
entry:
  %cast1 = bitcast float bitcast ( i32 250 to float ) to i32
  %cast2 = bitcast i32 %cast1 to float
  %cast3 = bitcast float %cast2 to i32
  %gep = getelementptr i64, i64* null, i32 %cast3
  ret void
}

; CHECK-LABEL: define void @test4(i32* %in, float* %out) {
; CHECK: entry:
; CHECK:   %0 = bitcast i32* %in to float*
; CHECK:   %1 = getelementptr float, float* %0, i32 1
; CHECK:   %val = load float, float* %1, align 4
; CHECK:   store float %val, float* %out, align 4
; CHECK:   ret void
; CHECK: }

define void @test4(i32* %in, float* %out) {
entry:
  %gep = getelementptr i32, i32* %in, i32 1     
  %cast = bitcast i32* %gep to float*
  %val = load float, float* %cast
  store float %val, float* %out
  ret void
}

; CHECK-LABEL: define void @test5(i32* %in) {
; CHECK: entry:
; CHECK:   %0 = getelementptr i32, i32* %in, i32 2
; CHECK:   ret void
; CHECK: }

define void @test5(i32* %in) {
entry:
  %gep1 = getelementptr i32, i32* %in, i32 1
  %gep2 = getelementptr i32, i32* %gep1, i32 1   
  ret void
}
