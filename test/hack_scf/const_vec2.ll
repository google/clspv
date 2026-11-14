; RUN: clspv-opt --hack-scf --passes=signed-compare-fixup %s -o %t
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @foo(<2 x i32> %x) {
entry:
  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor <2 x i32> %x, splat (i32 -2147483648)
  ; CHECK: icmp ugt <2 x i32> [[x_flipped]], splat (i32 -2147483644)
  %sgt = icmp sgt <2 x i32> %x, <i32 4, i32 4>

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor <2 x i32> %x, splat (i32 -2147483648)
  ; CHECK: icmp uge <2 x i32> [[x_flipped]], splat (i32 -2147483642)
  %sge = icmp sge <2 x i32> %x, <i32 6, i32 6>

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor <2 x i32> %x, splat (i32 -2147483648)
  ; CHECK: icmp ult <2 x i32> [[x_flipped]], splat (i32 -2147483640)
  %slt = icmp slt <2 x i32> %x, <i32 8, i32 8>

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor <2 x i32> %x, splat (i32 -2147483648)
  ; CHECK: icmp ule <2 x i32> [[x_flipped]], splat (i32 -2147483638)
  %sle = icmp sle <2 x i32> %x, <i32 10, i32 10>

  ret void
}

