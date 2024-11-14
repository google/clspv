; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer --producer-out-file %t.spv
; RUN: FileCheck %s < %t.ll

; CHECK: @array = global [8 x i8] zeroinitializer
; CHECK: [[ARRAY_PTR:[a-zA-Z0-9_]*]] = getelementptr inbounds [8 x i8], ptr @array, i32 0, i32 0
; CHECK: [[ARRAY_ALLOC:[a-zA-Z0-9_]*]] = alloca [8 x i8], align 8
; CHECK: %[[GET_ELE_PTR:[a-zA-Z0-9_]*]] = getelementptr [8 x i8], ptr %{{.*}}.[[ARRAY_ALLOC]], i32 0

; CHECK: %[[BITCAST1:[a-zA-Z0-9_]*]] = bitcast <1 x i64> splat (i64 369832251558649162) to <4 x i16>
; CHECK: %[[EXTRACT_ELE1:[a-zA-Z0-9_]*]] = extractelement <4 x i16> %[[BITCAST1]], i32 0
; CHECK: %[[INSERT_ELE1:[a-zA-Z0-9_]*]] = insertelement <2 x i16> {{.*}}, i16 %[[EXTRACT_ELE1]], i64 0
; CHECK: %[[BITCAST2:[a-zA-Z0-9_]*]] = bitcast <1 x i64> splat (i64 369832251558649162) to <4 x i16>
; CHECK: %[[EXTRACT_ELE2:[a-zA-Z0-9_]*]] = extractelement <4 x i16> %[[BITCAST2]], i32 1
; CHECK: %[[INSERT_ELE2:[a-zA-Z0-9_]*]] = insertelement <2 x i16> %[[INSERT_ELE1]], i16 %[[EXTRACT_ELE2]], i64 1
; CHECK: %[[BITCAST3:[a-zA-Z0-9_]*]] = bitcast <2 x i16> %[[INSERT_ELE2]] to <4 x i8>
; CHECK: %[[ELEMENT1:[a-zA-Z0-9_]*]] = extractelement <4 x i8> %[[BITCAST3]], i64 0
; CHECK: %[[INSERT_VALUE1:[a-zA-Z0-9_]*]] = insertvalue [8 x i8] {{.*}}, i8 %[[ELEMENT1]]

; CHECK: %[[BITCAST4:[a-zA-Z0-9_]*]] = bitcast <1 x i64> splat (i64 369832251558649162) to <4 x i16>
; CHECK: %[[EXTRACT_ELE3:[a-zA-Z0-9_]*]] = extractelement <4 x i16> %[[BITCAST4]], i32 0
; CHECK: %[[INSERT_ELE3:[a-zA-Z0-9_]*]] = insertelement <2 x i16> {{.*}}, i16 %[[EXTRACT_ELE3]], i64 0
; CHECK: %[[BITCAST5:[a-zA-Z0-9_]*]] = bitcast <1 x i64> splat (i64 369832251558649162) to <4 x i16>
; CHECK: %[[EXTRACT_ELE4:[a-zA-Z0-9_]*]] = extractelement <4 x i16> %[[BITCAST5]], i32 1
; CHECK: %[[INSERT_ELE4:[a-zA-Z0-9_]*]] = insertelement <2 x i16> %[[INSERT_ELE3]], i16 %[[EXTRACT_ELE4]], i64 1
; CHECK: %[[BITCAST6:[a-zA-Z0-9_]*]] = bitcast <2 x i16> %[[INSERT_ELE4]] to <4 x i8>
; CHECK: %[[ELEMENT2:[a-zA-Z0-9_]*]] = extractelement <4 x i8> %[[BITCAST6]]
; CHECK: %[[INSERT_VALUE2:[a-zA-Z0-9_]*]] = insertvalue [8 x i8] %[[INSERT_VALUE1]], i8 %[[ELEMENT2]]
; CHECK: store [8 x i8] %{{.*}}, ptr %[[GET_ELE_PTR]], align 1  

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Define the global variable `array` as an array of 2 i8's.
@array = global [8 x i8] zeroinitializer
@extracted_element = global i8 0

; Define the function `main`.
define i32 @main() {
entry:
  ; Extract the first element from the array `array`.
  %element = getelementptr inbounds [8 x i8], [8 x i8]* @array, i32 0, i32 0
  %extracted_element = load i8, i8* %element

  ; Store the extracted element to the global variable `extracted_element`.
  store i8 %extracted_element, i8* @extracted_element

  %iv.i = alloca [8 x i8], align 8
  %0 = getelementptr [8 x i8], ptr %iv.i, i32 0
  store [8 x i8] [i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 0), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 1)> to <4 x i8>), i64 0), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 0), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 1)> to <4 x i8>), i64 1), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 0), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 1)> to <4 x i8>), i64 2), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 0), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 1)> to <4 x i8>), i64 3), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 2), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 3)> to <4 x i8>), i64 0), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 2), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 3)> to <4 x i8>), i64 1), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 2), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 3)> to <4 x i8>), i64 2), i8 extractelement (<4 x i8> bitcast (<2 x i16> <i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 2), i16 extractelement (<4 x i16> bitcast (<1 x i64> <i64 369832251558649162> to <4 x i16>), i32 3)> to <4 x i8>), i64 3)], ptr %0, align 1
  
  ret i32 0
}
