; RUN: clspv-opt --passes=signed-compare-fixup -hack-scf %s -o %t.ll
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define <4 x i1> @greater_than(<4 x i32> %x) {
entry:
  %cmp = icmp sgt <4 x i32> %x, <i32 0, i32 1, i32 2, i32 3>
  ret <4 x i1> %cmp
}

; CHECK: [[x_flipped:%[a-zA-Z0-9_.]+]] = xor <4 x i32> %x, splat (i32 -2147483648)
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp ugt <4 x i32> [[x_flipped]], <i32 -2147483648, i32 -2147483647, i32 -2147483646, i32 -2147483645>
; CHECK: ret <4 x i1> [[cmp]]

