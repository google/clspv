; RUN: clspv-opt %s -o %t.ll --passes=three-element-vector-lowering -vec3-to-vec4
; RUN: FileCheck %s < %t.ll

; CHECK-DAG: bitcast <4 x i64> %{{.*}} to <32 x i8>
; CHECK-DAG: bitcast <4 x i16> %{{.*}} to <8 x i8>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define linkonce_odr dso_local spir_func <3 x i8> @ushort3(<3 x i16> noundef %0) {
  %2 = shufflevector <3 x i16> %0, <3 x i16> poison, <2 x i32> <i32 0, i32 1>
  %3 = trunc <2 x i16> %2 to <2 x i8>
  %4 = shufflevector <2 x i8> %3, <2 x i8> poison, <3 x i32> <i32 0, i32 1, i32 undef>
  %5 = bitcast <3 x i16> %0 to <6 x i8>
  %6 = extractelement <6 x i8> %5, i64 4
  %7 = insertelement <3 x i8> %4, i8 %6, i64 2
  ret <3 x i8> %7
}

define linkonce_odr dso_local spir_func <3 x i8> @ulong3(<3 x i64> noundef %0) {
  %2 = shufflevector <3 x i64> %0, <3 x i64> poison, <2 x i32> <i32 0, i32 1>
  %3 = trunc <2 x i64> %2 to <2 x i8>
  %4 = shufflevector <2 x i8> %3, <2 x i8> poison, <3 x i32> <i32 0, i32 1, i32 undef>
  %5 = bitcast <3 x i64> %0 to <24 x i8>
  %6 = extractelement <24 x i8> %5, i64 4
  %7 = insertelement <3 x i8> %4, i8 %6, i64 2
  ret <3 x i8> %7
}

