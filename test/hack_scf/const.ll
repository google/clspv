; RUN: clspv-opt --hack-scf --passes=signed-compare-fixup %s -o %t
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @foo(i32 %x) {
entry:
  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor i32 %x, -2147483648
  ; CHECK: icmp ugt i32 [[x_flipped]], -2147483644
  %sgt = icmp sgt i32 %x, 4

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor i32 %x, -2147483648
  ; CHECK: icmp uge i32 [[x_flipped]], -2147483642
  %sge = icmp sge i32 %x, 6

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor i32 %x, -2147483648
  ; CHECK: icmp ult i32 [[x_flipped]], -2147483640
  %slt = icmp slt i32 %x, 8

  ; CHECK: [[x_flipped:%[a-zA-Z0-9_]+]] = xor i32 %x, -2147483648
  ; CHECK: icmp ule i32 [[x_flipped]], -2147483638
  %sle = icmp sle i32 %x, 10

  ret void
}
