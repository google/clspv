; RUN: clspv-opt --passes=signed-compare-fixup -hack-scf %s -o %t.ll
; RUN: FileCheck %s --implicit-check-not="icmp s" < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define i1 @less_equal(i32 %x, i32 %y) {
entry:
  %cmp = icmp sle i32 %x, %y
  ret i1 %cmp
}

; CHECK: [[x_flipped:%[a-zA-Z0-9_.]+]] = xor i32 %x, -2147483648
; CHECK: [[y_flipped:%[a-zA-Z0-9_.]+]] = xor i32 %y, -2147483648
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp ule i32 [[x_flipped]], [[y_flipped]]
; CHECK: ret i1 [[cmp]]

