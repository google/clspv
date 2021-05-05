; RUN: clspv-opt -hack-scf -SignedCompareFixupPass %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: smax
; CHECK: [[b_m_a:%[0-9]+]] = sub i32 %b, %a
; CHECK: [[m_1:%[0-9]+]] = sub i32 [[b_m_a]], 1
; CHECK: [[and:%[0-9]+]] = and i32 [[m_1]], -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp eq i32 [[and]], 0
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 %b, i32 %a
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @smax(i32 %a, i32 %b) {
entry:
  %max = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  ret i32 %max
}

declare i32 @llvm.smax.i32(i32, i32)

; CHECK-LABEL: smax3
; CHECK: [[b_m_a:%[0-9]+]] = sub <3 x i32> %b, %a
; CHECK: [[m_1:%[0-9]+]] = sub <3 x i32> [[b_m_a]], <i32 1, i32 1, i32 1>
; CHECK: [[and:%[0-9]+]] = and <3 x i32> [[m_1]], <i32 -2147483648, i32 -2147483648, i32 -2147483648>
; CHECK: [[cmp:%[0-9]+]] = icmp eq <3 x i32> [[and]], zeroinitializer
; CHECK: [[sel:%[0-9]+]] = select <3 x i1> [[cmp]], <3 x i32> %b, <3 x i32> %a
; CHECK: ret <3 x i32> [[sel]]

define <3 x i32> @smax3(<3 x i32> %a, <3 x i32> %b) {
entry:
  %max3 = call <3 x i32> @llvm.smax.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %max3
}

declare <3 x i32> @llvm.smax.v3i32(<3 x i32>, <3 x i32>)
