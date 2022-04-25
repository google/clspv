; RUN: clspv-opt -hack-scf --passes=signed-compare-fixup %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: smin
; CHECK: [[a_m_b:%[0-9]+]] = sub i32 %a, %b
; CHECK: [[m_1:%[0-9]+]] = sub i32 [[a_m_b]], 1
; CHECK: [[and:%[0-9]+]] = and i32 [[m_1]], -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp eq i32 [[and]], 0
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 %b, i32 %a
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @smin(i32 %a, i32 %b) {
entry:
  %min = call i32 @llvm.smin.i32(i32 %a, i32 %b)
  ret i32 %min
}

declare i32 @llvm.smin.i32(i32, i32)

; CHECK-LABEL: smin2
; CHECK: [[a_m_b:%[0-9]+]] = sub <2 x i32> %a, %b
; CHECK: [[m_1:%[0-9]+]] = sub <2 x i32> [[a_m_b]], <i32 1, i32 1>
; CHECK: [[and:%[0-9]+]] = and <2 x i32> [[m_1]], <i32 -2147483648, i32 -2147483648>
; CHECK: [[cmp:%[0-9]+]] = icmp eq <2 x i32> [[and]], zeroinitializer
; CHECK: [[sel:%[0-9]+]] = select <2 x i1> [[cmp]], <2 x i32> %b, <2 x i32> %a
; CHECK: ret <2 x i32> [[sel]]

define <2 x i32> @smin2(<2 x i32> %a, <2 x i32> %b) {
entry:
  %min3 = call <2 x i32> @llvm.smin.v3i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %min3
}

declare <2 x i32> @llvm.smin.v3i32(<2 x i32>, <2 x i32>)
