; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; This tests covers UndefValue, ConstantAggregateZero and ConstantDataVector.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x float> @test1() {
  ret <8 x float> zeroinitializer
}

define spir_func <8 x i32> @test2() {
  ret <8 x i32> zeroinitializer
}

define spir_func <16 x float> @test3() {
  ret <16 x float> undef
}

define spir_func <16 x i32> @test4() {
  ret <16 x i32> undef
}

define spir_func <8 x float> @test5() {
  ret <8 x float> <float 0.0, float 1.0, float 2.0, float 3.0, float 4.0, float 5.0, float 6.0, float 7.0>
}

define spir_func <8 x i32> @test6() {
  ret <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
}

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[INT8:\[8 x i32\]]]
; CHECK-SAME: @test6()
; CHECK-NEXT: ret [[INT8]] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT8:\[8 x float\]]]
; CHECK-SAME: @test5()
; CHECK-NEXT: ret [[FLOAT8]] [float 0[[SUFFIX:\.0+e\+0+]], float 1[[SUFFIX]], float 2[[SUFFIX]],
; CHECK-SAME: float 3[[SUFFIX]], float 4[[SUFFIX]], float 5[[SUFFIX]], float 6[[SUFFIX]], float 7[[SUFFIX]]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[INT16:\[16 x i32\]]]
; CHECK-SAME: @test4()
; CHECK-NEXT: ret [[INT16]] undef

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT16:\[16 x float\]]]
; CHECK-SAME: @test3()
; CHECK-NEXT: ret [[FLOAT16]] undef

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[INT8]]
; CHECK-SAME: @test2()
; CHECK-NEXT: ret [[INT8]] zeroinitializer

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT8]]
; CHECK-SAME: @test1()
; CHECK-NEXT: ret [[FLOAT8]] zeroinitializer
