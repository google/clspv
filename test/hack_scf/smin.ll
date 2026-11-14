; RUN: clspv-opt -hack-scf --passes=signed-compare-fixup %s -o %t.ll
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t.ll

; CHECK-LABEL: smin
; CHECK: [[b_flipped:%[0-9]+]] = xor i32 %b, -2147483648
; CHECK: [[a_flipped:%[0-9]+]] = xor i32 %a, -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp ult i32 [[b_flipped]], [[a_flipped]]
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 %b, i32 %a
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define i32 @smin(i32 %a, i32 %b) {
entry:
  %min = call spir_func i32 @_Z3minii(i32 %a, i32 %b)
  ret i32 %min
}

declare spir_func i32 @_Z3minii(i32, i32)

; CHECK-LABEL: smin2
; CHECK: [[b_flipped:%[0-9]+]] = xor <2 x i32> %b, splat (i32 -2147483648)
; CHECK: [[a_flipped:%[0-9]+]] = xor <2 x i32> %a, splat (i32 -2147483648)
; CHECK: [[cmp:%[0-9]+]] = icmp ult <2 x i32> [[b_flipped]], [[a_flipped]]
; CHECK: [[sel:%[0-9]+]] = select <2 x i1> [[cmp]], <2 x i32> %b, <2 x i32> %a
; CHECK: ret <2 x i32> [[sel]]

define <2 x i32> @smin2(<2 x i32> %a, <2 x i32> %b) {
entry:
  %min2 = call spir_func <2 x i32> @_Z3minDv2_iS_(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %min2
}

declare spir_func <2 x i32> @_Z3minDv2_iS_(<2 x i32>, <2 x i32>)
