; RUN: clspv-opt -hack-scf --passes=signed-compare-fixup %s -o %t.ll
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t.ll

; CHECK-LABEL: smax
; CHECK: [[a_flipped:%[0-9]+]] = xor i32 %a, -2147483648
; CHECK: [[b_flipped:%[0-9]+]] = xor i32 %b, -2147483648
; CHECK: [[cmp:%[0-9]+]] = icmp ult i32 [[a_flipped]], [[b_flipped]]
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 %b, i32 %a
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define i32 @smax(i32 %a, i32 %b) {
entry:
  %max = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  ret i32 %max
}

declare i32 @llvm.smax.i32(i32, i32)

; CHECK-LABEL: smax3
; CHECK: [[a_flipped:%[0-9]+]] = xor <3 x i32> %a, splat (i32 -2147483648)
; CHECK: [[b_flipped:%[0-9]+]] = xor <3 x i32> %b, splat (i32 -2147483648)
; CHECK: [[cmp:%[0-9]+]] = icmp ult <3 x i32> [[a_flipped]], [[b_flipped]]
; CHECK: [[sel:%[0-9]+]] = select <3 x i1> [[cmp]], <3 x i32> %b, <3 x i32> %a
; CHECK: ret <3 x i32> [[sel]]

define <3 x i32> @smax3(<3 x i32> %a, <3 x i32> %b) {
entry:
  %max3 = call <3 x i32> @llvm.smax.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %max3
}

declare <3 x i32> @llvm.smax.v3i32(<3 x i32>, <3 x i32>)
