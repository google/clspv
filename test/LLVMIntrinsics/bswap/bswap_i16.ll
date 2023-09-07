; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: [[shl:%[^ ]+]] = shl i16 %input, 8
; CHECK: [[lshr:%[^ ]+]] = lshr i16 %input, 8
; CHECK: or i16 [[shl]], [[lshr]]

declare i16 @llvm.bswap.i16(i16)

define dso_local spir_kernel void @kernel(i16 %input) {
entry:
  %0 = call i16 @llvm.bswap.i16(i16 %input)
  ret void
}
