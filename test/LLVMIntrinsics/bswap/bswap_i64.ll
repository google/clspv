; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK:  [[byte7:%[^ ]+]] = shl i64 %input, 56
; CHECK:  [[and:%[^ ]+]] = and i64 %input, 65280
; CHECK:  [[byte6:%[^ ]+]] = shl i64 [[and]], 40
; CHECK:  [[and:%[^ ]+]] = and i64 %input, 16711680
; CHECK:  [[byte5:%[^ ]+]] = shl i64 [[and]], 24
; CHECK:  [[and:%[^ ]+]] = and i64 %input, 4278190080
; CHECK:  [[byte4:%[^ ]+]] = shl i64 [[and]], 8
; CHECK:  [[lshr:%[^ ]+]] = lshr i64 %input, 8
; CHECK:  [[byte3:%[^ ]+]] = and i64 [[lshr]], 4278190080
; CHECK:  [[lshr:%[^ ]+]] = lshr i64 %input, 24
; CHECK:  [[byte2:%[^ ]+]] = and i64 [[lshr]], 16711680
; CHECK:  [[lshr:%[^ ]+]] = lshr i64 %input, 40
; CHECK:  [[byte1:%[^ ]+]] = and i64 [[lshr]], 65280
; CHECK:  [[byte0:%[^ ]+]] = lshr i64 %input, 56
; CHECK:  [[bswap76:%[^ ]+]] = or i64 [[byte7]], [[byte6]]
; CHECK:  [[bswap765:%[^ ]+]] = or i64 [[bswap76]], [[byte5]]
; CHECK:  [[bswap7654:%[^ ]+]] = or i64 [[bswap765]], [[byte4]]
; CHECK:  [[bswap76543:%[^ ]+]] = or i64 [[bswap7654]], [[byte3]]
; CHECK:  [[bswap765432:%[^ ]+]] = or i64 [[bswap76543]], [[byte2]]
; CHECK:  [[bswap7654321:%[^ ]+]] = or i64 [[bswap765432]], [[byte1]]
; CHECK:  or i64 [[bswap7654321]], [[byte0]]

declare i64 @llvm.bswap.i64(i64)

define dso_local spir_kernel void @kernel(i64 %input) {
entry:
  %0 = call i64 @llvm.bswap.i64(i64 %input)
  ret void
}
