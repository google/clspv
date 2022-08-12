; RUN: clspv-opt %s -o %t --passes=long-vector-lowering
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct = type { i8, <8 x i32> }

define void @test1(%struct addrspace(1)* %ptr) {
entry:
    %0 = getelementptr %struct, %struct addrspace(1)* %ptr, i32 0, i32 1
    ret void
}

define <8 x i32> @test2(%struct %s) {
entry:
    %0 = extractvalue %struct %s, 1
    ret <8 x i32> %0
}

define void @test3(%struct %s, <8 x i32> %val) {
entry:
    %0 = insertvalue %struct %s, <8 x i32> %val, 1
    ret void
}

; CHECK-LABEL: @test3(
; CHECK:  extractvalue { i8, [7 x i32], [8 x i32] } %s, 0
; CHECK:  insertvalue { i8, [7 x i32], [8 x i32] } undef, i8 {{.*}}, 0
; CHECK:  extractvalue { i8, [7 x i32], [8 x i32] } %s, 2
; CHECK:  insertvalue { i8, [7 x i32], [8 x i32] } {{.*}}, [8 x i32] {{.*}}, 2
; CHECK:  insertvalue { i8, [7 x i32], [8 x i32] } {{.*}}, [8 x i32] {{.*}}, 2

; CHECK-LABEL: @test2(
; CHECK: extractvalue { i8, [7 x i32], [8 x i32] } %s, 0
; CHECK: insertvalue { i8, [7 x i32], [8 x i32] } undef, i8 {{.*}}, 0
; CHECK: extractvalue { i8, [7 x i32], [8 x i32] } %s, 2

; CHECK-LABEL: @test1(
; CHECK: getelementptr { i8, [7 x i32], [8 x i32] }, { i8, [7 x i32], [8 x i32] } addrspace(1)* %ptr, i32 0, i32 2
