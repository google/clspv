; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK:  [[byte3:%[^ ]+]] = shl i32 %input, 24
; CHECK:  [[and:%[^ ]+]] = and i32 %input, 65280
; CHECK:  [[byte2:%[^ ]+]] = shl i32 [[and]], 8
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %input, 8
; CHECK:  [[byte1:%[^ ]+]] = and i32 [[lshr]], 65280
; CHECK:  [[byte0:%[^ ]+]] = lshr i32 %input, 24
; CHECK:  [[bswap32:%[^ ]+]] = or i32 [[byte3]], [[byte2]]
; CHECK:  [[bswap321:%[^ ]+]] = or i32 [[bswap32]], [[byte1]]
; CHECK:  or i32 [[bswap321]], [[byte0]]

declare i32 @llvm.bswap.i32(i32)

define dso_local spir_kernel void @kernel(i32 %input) {
entry:
  %0 = call i32 @llvm.bswap.i32(i32 %input)
  ret void
}
