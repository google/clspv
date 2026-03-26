; RUN: clspv-opt %s -o %t --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v64:64-v96:128-v128:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare i1 @llvm.is.fpclass.f32(float, i32)
declare i1 @llvm.is.fpclass.f64(double, i32)
declare <2 x i1> @llvm.is.fpclass.v2f32(<2 x float>, i32)

define i1 @test_is_nan_f32(float %a) {
  %b = call i1 @llvm.is.fpclass.f32(float %a, i32 3) ; 0x01 | 0x02
  ret i1 %b
}

; CHECK: define i1 @test_is_nan_f32(float %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast float %a to i32
; CHECK-NEXT: lshr
; CHECK-NEXT: icmp
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[EXP:[0-9]+]] = and i32 %[[BITCAST]], 2139095040
; CHECK-NEXT: %[[SIG:[0-9]+]] = and i32 %[[BITCAST]], 8388607
; CHECK-NEXT: %[[IS_EXP_ALL_ONES:[0-9]+]] = icmp eq i32 %[[EXP]], 2139095040
; CHECK-NEXT: %[[IS_SIG_NON_ZERO:[0-9]+]] = icmp ne i32 %[[SIG]], 0
; CHECK-NEXT: %[[IS_NAN:[0-9]+]] = and i1 %[[IS_EXP_ALL_ONES]], %[[IS_SIG_NON_ZERO]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or i1 false, %[[IS_NAN]]
; CHECK-NEXT: ret i1 %[[OR]]

define i1 @test_is_inf_f32(float %a) {
  %b = call i1 @llvm.is.fpclass.f32(float %a, i32 516) ; 0x04 | 0x200
  ret i1 %b
}

; CHECK: define i1 @test_is_inf_f32(float %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast float %a to i32
; CHECK-NEXT: lshr
; CHECK-NEXT: icmp
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[EXP:[0-9]+]] = and i32 %[[BITCAST]], 2139095040
; CHECK-NEXT: %[[SIG:[0-9]+]] = and i32 %[[BITCAST]], 8388607
; CHECK-NEXT: %[[IS_EXP_ALL_ONES:[0-9]+]] = icmp eq i32 %[[EXP]], 2139095040
; CHECK-NEXT: %[[IS_SIG_ZERO:[0-9]+]] = icmp eq i32 %[[SIG]], 0
; CHECK-NEXT: %[[IS_INF:[0-9]+]] = and i1 %[[IS_EXP_ALL_ONES]], %[[IS_SIG_ZERO]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or i1 false, %[[IS_INF]]
; CHECK-NEXT: ret i1 %[[OR]]

define i1 @test_is_pos_zero_f32(float %a) {
  %b = call i1 @llvm.is.fpclass.f32(float %a, i32 64) ; 0x40
  ret i1 %b
}

; CHECK: define i1 @test_is_pos_zero_f32(float %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast float %a to i32
; CHECK-NEXT: %[[SIGN_BIT:[0-9]+]] = lshr i32 %[[BITCAST]], 31
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[IS_POS:[0-9]+]] = icmp eq i32 %[[SIGN_BIT]], 0
; CHECK-NEXT: %[[EXP:[0-9]+]] = and i32 %[[BITCAST]], 2139095040
; CHECK-NEXT: %[[SIG:[0-9]+]] = and i32 %[[BITCAST]], 8388607
; CHECK-NEXT: %[[IS_EXP_ZERO:[0-9]+]] = icmp eq i32 %[[EXP]], 0
; CHECK-NEXT: %[[IS_SIG_ZERO:[0-9]+]] = icmp eq i32 %[[SIG]], 0
; CHECK-NEXT: %[[IS_ZERO:[0-9]+]] = and i1 %[[IS_EXP_ZERO]], %[[IS_SIG_ZERO]]
; CHECK-NEXT: %[[IS_POS_ZERO:[0-9]+]] = and i1 %[[IS_ZERO]], %[[IS_POS]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or i1 false, %[[IS_POS_ZERO]]
; CHECK-NEXT: ret i1 %[[OR]]

define i1 @test_is_neg_normal_f32(float %a) {
  %b = call i1 @llvm.is.fpclass.f32(float %a, i32 8) ; 0x08
  ret i1 %b
}

; CHECK: define i1 @test_is_neg_normal_f32(float %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast float %a to i32
; CHECK-NEXT: %[[SIGN_BIT:[0-9]+]] = lshr i32 %[[BITCAST]], 31
; CHECK-NEXT: %[[IS_NEG:[0-9]+]] = icmp eq i32 %[[SIGN_BIT]], 1
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[EXP:[0-9]+]] = and i32 %[[BITCAST]], 2139095040
; CHECK-NEXT: and
; CHECK-NEXT: %[[NOT_EXP_ZERO:[0-9]+]] = icmp ne i32 %[[EXP]], 0
; CHECK-NEXT: %[[NOT_EXP_ALL_ONES:[0-9]+]] = icmp ne i32 %[[EXP]], 2139095040
; CHECK-NEXT: %[[IS_NORM:[0-9]+]] = and i1 %[[NOT_EXP_ZERO]], %[[NOT_EXP_ALL_ONES]]
; CHECK-NEXT: %[[IS_NEG_NORM:[0-9]+]] = and i1 %[[IS_NORM]], %[[IS_NEG]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or i1 false, %[[IS_NEG_NORM]]
; CHECK-NEXT: ret i1 %[[OR]]

define i1 @test_is_any_f32(float %a) {
  %b = call i1 @llvm.is.fpclass.f32(float %a, i32 1023) ; All flags
  ret i1 %b
}

; CHECK: define i1 @test_is_any_f32(float %a)
; CHECK-NEXT: bitcast float %a to i32
; CHECK: %[[OR1:[0-9]+]] = or i1 false, {{.*}}
; CHECK: %[[OR2:[0-9]+]] = or i1 %[[OR1]]
; CHECK: %[[OR3:[0-9]+]] = or i1 %[[OR2]]
; CHECK: %[[OR4:[0-9]+]] = or i1 %[[OR3]]
; CHECK: %[[OR5:[0-9]+]] = or i1 %[[OR4]]
; CHECK-NEXT: ret i1 %[[OR5]]

define <2 x i1> @test_is_nan_v2f32(<2 x float> %a) {
  %b = call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 3)
  ret <2 x i1> %b
}

; CHECK: define <2 x i1> @test_is_nan_v2f32(<2 x float> %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast <2 x float> %a to <2 x i32>
; CHECK-NEXT: lshr
; CHECK-NEXT: icmp
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[EXP:[0-9]+]] = and <2 x i32> %[[BITCAST]], splat (i32 2139095040)
; CHECK-NEXT: %[[SIG:[0-9]+]] = and <2 x i32> %[[BITCAST]], splat (i32 8388607)
; CHECK-NEXT: %[[IS_EXP_ALL_ONES:[0-9]+]] = icmp eq <2 x i32> %[[EXP]], splat (i32 2139095040)
; CHECK-NEXT: %[[IS_SIG_NON_ZERO:[0-9]+]] = icmp ne <2 x i32> %[[SIG]], zeroinitializer
; CHECK-NEXT: %[[IS_NAN:[0-9]+]] = and <2 x i1> %[[IS_EXP_ALL_ONES]], %[[IS_SIG_NON_ZERO]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or <2 x i1> zeroinitializer, %[[IS_NAN]]
; CHECK-NEXT: ret <2 x i1> %[[OR]]

define i1 @test_is_nan_f64(double %a) {
  %b = call i1 @llvm.is.fpclass.f64(double %a, i32 3) ; 0x01 | 0x02
  ret i1 %b
}

; CHECK: define i1 @test_is_nan_f64(double %a)
; CHECK-NEXT: %[[BITCAST:[0-9]+]] = bitcast double %a to i64
; CHECK-NEXT: lshr
; CHECK-NEXT: icmp
; CHECK-NEXT: icmp
; CHECK-NEXT: %[[EXP:[0-9]+]] = and i64 %[[BITCAST]], 9218868437227405312
; CHECK-NEXT: %[[SIG:[0-9]+]] = and i64 %[[BITCAST]], 4503599627370495
; CHECK-NEXT: %[[IS_EXP_ALL_ONES:[0-9]+]] = icmp eq i64 %[[EXP]], 9218868437227405312
; CHECK-NEXT: %[[IS_SIG_NON_ZERO:[0-9]+]] = icmp ne i64 %[[SIG]], 0
; CHECK-NEXT: %[[IS_NAN:[0-9]+]] = and i1 %[[IS_EXP_ALL_ONES]], %[[IS_SIG_NON_ZERO]]
; CHECK-NEXT: %[[OR:[0-9]+]] = or i1 false, %[[IS_NAN]]
; CHECK-NEXT: ret i1 %[[OR]]
