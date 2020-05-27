; RUN: clspv-opt -hack-scf -SignedCompareFixupPass %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LABEL: sclamp
; CHECK: [[b_m_a:%[0-9]+]] = sub i32 %b, %a
; CHECK: [[m_1:%[0-9]+]] = sub i32 [[b_m_a]], 1
; CHECK: [[and:%[0-9]+]] = and i32 [[m_1]], -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp eq i32 [[and]], 0
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 %b, i32 %a
; CHECK: [[a_m_c:%[0-9]+]] = sub i32 %a, %c
; CHECK: [[m_1:%[0-9]+]] = sub i32 [[a_m_c]], 1
; CHECK: [[and:%[0-9]+]] = and i32 [[m_1]], -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp eq i32 [[and]], 0
; CHECK: [[sel2:%[0-9]+]] = select i1 [[cmp]], i32 %c, i32 [[sel]]
; CHECK: ret i32 [[sel2]]

define i32 @sclamp(i32 %a, i32 %b, i32 %c) {
entry:
  %clamp = call spir_func i32 @_Z5clampiii(i32 %a, i32 %b, i32 %c)
  ret i32 %clamp
}

declare spir_func i32 @_Z5clampiii(i32, i32, i32)

; CHECK-LABEL: sclamp4
; CHECK: [[b_m_a:%[0-9]+]] = sub <4 x i32> %b, %a
; CHECK: [[m_1:%[0-9]+]] = sub <4 x i32> [[b_m_a]], <i32 1, i32 1, i32 1, i32 1>
; CHECK: [[and:%[0-9]+]] = and <4 x i32> [[m_1]], <i32 -2147483648, i32 -2147483648, i32 -2147483648, i32 -2147483648>
; CHECK: [[cmp:%[0-9]+]] = icmp eq <4 x i32> [[and]], zeroinitializer
; CHECK: [[sel:%[0-9]+]] = select <4 x i1> [[cmp]], <4 x i32> %b, <4 x i32> %a
; CHECK: [[a_m_c:%[0-9]+]] = sub <4 x i32> %a, %c
; CHECK: [[m_1:%[0-9]+]] = sub <4 x i32> [[a_m_c]], <i32 1, i32 1, i32 1, i32 1>
; CHECK: [[and:%[0-9]+]] = and <4 x i32> [[m_1]], <i32 -2147483648, i32 -2147483648, i32 -2147483648, i32 -2147483648>
; CHECK: [[cmp:%[0-9]+]] = icmp eq <4 x i32> [[and]], zeroinitializer
; CHECK: [[sel2:%[0-9]+]] = select <4 x i1> [[cmp]], <4 x i32> %c, <4 x i32> [[sel]]
; CHECK: ret <4 x i32> [[sel2]]

define <4 x i32> @sclamp4(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) {
entry:
  %clamp4 = call spir_func <4 x i32> @_Z5clampDv4_iS_S_(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %clamp4
}

declare spir_func <4 x i32> @_Z5clampDv4_iS_S_(<4 x i32>, <4 x i32>, <4 x i32>)
