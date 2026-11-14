; RUN: clspv-opt --hack-scf --passes=signed-compare-fixup %s -o %t
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; The old subtraction-based lowering overflowed for inputs far apart (e.g.
; 127 - (-113) wraps in i8).
; CHECK-LABEL: @overflow
define i1 @overflow(i8 %a, i8 %b) {
entry:
  ; CHECK: [[a_flipped:%[a-zA-Z0-9_]+]] = xor i8 %a, -128
  ; CHECK: [[b_flipped:%[a-zA-Z0-9_]+]] = xor i8 %b, -128
  ; CHECK: [[cmp:%[a-zA-Z0-9_]+]] = icmp ugt i8 [[a_flipped]], [[b_flipped]]
  ; CHECK: ret i1 [[cmp]]
  %cmp = icmp sgt i8 %a, %b
  ret i1 %cmp
}

; Exact constant case from issue #1041: 0x7f (127) > -113 (0x8f).
; CHECK-LABEL: @overflow_i8_const
define i1 @overflow_i8_const() {
entry:
  ; CHECK: ret i1 true
  %cmp = icmp sgt i8 127, -113
  ret i1 %cmp
}

; CHECK-LABEL: @overflow_i16
define i1 @overflow_i16(i16 %a, i16 %b) {
entry:
  ; CHECK: [[a:%[a-zA-Z0-9_]+]] = xor i16 %a, -32768
  ; CHECK: [[b:%[a-zA-Z0-9_]+]] = xor i16 %b, -32768
  ; CHECK: [[cmp:%[a-zA-Z0-9_]+]] = icmp ule i16 [[a]], [[b]]
  ; CHECK: ret i1 [[cmp]]
  %cmp = icmp sle i16 %a, %b
  ret i1 %cmp
}

; CHECK-LABEL: @overflow_i64
define i1 @overflow_i64(i64 %a, i64 %b) {
entry:
  ; CHECK: [[a:%[a-zA-Z0-9_]+]] = xor i64 %a, -9223372036854775808
  ; CHECK: [[b:%[a-zA-Z0-9_]+]] = xor i64 %b, -9223372036854775808
  ; CHECK: [[cmp:%[a-zA-Z0-9_]+]] = icmp ult i64 [[a]], [[b]]
  ; CHECK: ret i1 [[cmp]]
  %cmp = icmp slt i64 %a, %b
  ret i1 %cmp
}

; Vector types and all 4 predicates with overflowing/boundary values.
; CHECK-LABEL: @overflow_v4i8_all_preds
define <4 x i1> @overflow_v4i8_all_preds(<4 x i8> %a) {
entry:
  ; CHECK: [[a1:%[a-zA-Z0-9_]+]] = xor <4 x i8> %a, splat (i8 -128)
  ; CHECK: [[c1:%[a-zA-Z0-9_]+]] = icmp ugt <4 x i8> [[a1]], <i8 -1, i8 15, i8 0, i8 127>
  %c1 = icmp sgt <4 x i8> %a, <i8 127, i8 -113, i8 -128, i8 -1>
  ; CHECK: [[a2:%[a-zA-Z0-9_]+]] = xor <4 x i8> %a, splat (i8 -128)
  ; CHECK: [[c2:%[a-zA-Z0-9_]+]] = icmp uge <4 x i8> [[a2]], zeroinitializer
  %c2 = icmp sge <4 x i8> %a, <i8 -128, i8 -128, i8 -128, i8 -128>
  ; CHECK: [[a3:%[a-zA-Z0-9_]+]] = xor <4 x i8> %a, splat (i8 -128)
  ; CHECK: [[c3:%[a-zA-Z0-9_]+]] = icmp ult <4 x i8> splat (i8 -1), [[a3]]
  %c3 = icmp slt <4 x i8> <i8 127, i8 127, i8 127, i8 127>, %a
  ; CHECK: [[a4:%[a-zA-Z0-9_]+]] = xor <4 x i8> %a, splat (i8 -128)
  ; CHECK: [[c4:%[a-zA-Z0-9_]+]] = icmp ule <4 x i8> [[a4]], <i8 -128, i8 -127, i8 126, i8 -1>
  %c4 = icmp sle <4 x i8> %a, <i8 0, i8 1, i8 -2, i8 127>
  ; CHECK: %m1 = and <4 x i1> [[c1]], [[c2]]
  ; CHECK: %m2 = and <4 x i1> [[c3]], [[c4]]
  ; CHECK: %res = and <4 x i1> %m1, %m2
  ; CHECK: ret <4 x i1> %res
  %m1 = and <4 x i1> %c1, %c2
  %m2 = and <4 x i1> %c3, %c4
  %res = and <4 x i1> %m1, %m2
  ret <4 x i1> %res
}

; CHECK-LABEL: @overflow_v4i32_const_limits
define <4 x i1> @overflow_v4i32_const_limits() {
entry:
  ; CHECK: ret <4 x i1> <i1 true, i1 false, i1 false, i1 true>
  %cmp = icmp sgt <4 x i32> <i32 2147483647, i32 -2147483648, i32 -1, i32 0>, <i32 -2147483648, i32 2147483647, i32 1, i32 -1>
  ret <4 x i1> %cmp
}

declare i8 @llvm.smax.i8(i8, i8)

; CHECK-LABEL: @overflow_smax_i8
define i8 @overflow_smax_i8(i8 %a, i8 %b) {
entry:
  ; CHECK: [[a:%[a-zA-Z0-9_]+]] = xor i8 %a, -128
  ; CHECK: [[b:%[a-zA-Z0-9_]+]] = xor i8 %b, -128
  ; CHECK: [[cmp:%[a-zA-Z0-9_]+]] = icmp ult i8 [[a]], [[b]]
  ; CHECK: [[sel:%[a-zA-Z0-9_]+]] = select i1 [[cmp]], i8 %b, i8 %a
  ; CHECK: ret i8 [[sel]]
  %m = call i8 @llvm.smax.i8(i8 %a, i8 %b)
  ret i8 %m
}

; CHECK-LABEL: @overflow_smax_i8_const
define i8 @overflow_smax_i8_const() {
entry:
  ; CHECK: ret i8 127
  %m = call i8 @llvm.smax.i8(i8 127, i8 -113)
  ret i8 %m
}
