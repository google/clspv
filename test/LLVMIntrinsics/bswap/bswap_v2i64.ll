; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK:  [[byte7:%[^ ]+]] = shl <2 x i64> %input, <i64 56, i64 56>
; CHECK:  [[and:%[^ ]+]] = and <2 x i64> %input, <i64 65280, i64 65280>
; CHECK:  [[byte6:%[^ ]+]] = shl <2 x i64> [[and]], <i64 40, i64 40>
; CHECK:  [[and:%[^ ]+]] = and <2 x i64> %input, <i64 16711680, i64 16711680>
; CHECK:  [[byte5:%[^ ]+]] = shl <2 x i64> [[and]], <i64 24, i64 24>
; CHECK:  [[and:%[^ ]+]] = and <2 x i64> %input, <i64 4278190080, i64 4278190080>
; CHECK:  [[byte4:%[^ ]+]] = shl <2 x i64> [[and]], <i64 8, i64 8>
; CHECK:  [[lshr:%[^ ]+]] = lshr <2 x i64> %input, <i64 8, i64 8>
; CHECK:  [[byte3:%[^ ]+]] = and <2 x i64> [[lshr]], <i64 4278190080, i64 4278190080>
; CHECK:  [[lshr:%[^ ]+]] = lshr <2 x i64> %input, <i64 24, i64 24>
; CHECK:  [[byte2:%[^ ]+]] = and <2 x i64> [[lshr]], <i64 16711680, i64 16711680>
; CHECK:  [[lshr:%[^ ]+]] = lshr <2 x i64> %input, <i64 40, i64 40>
; CHECK:  [[byte1:%[^ ]+]] = and <2 x i64> [[lshr]], <i64 65280, i64 65280>
; CHECK:  [[byte0:%[^ ]+]] = lshr <2 x i64> %input, <i64 56, i64 56>
; CHECK:  [[bswap76:%[^ ]+]] = or <2 x i64> [[byte7]], [[byte6]]
; CHECK:  [[bswap765:%[^ ]+]] = or <2 x i64> [[bswap76]], [[byte5]]
; CHECK:  [[bswap7654:%[^ ]+]] = or <2 x i64> [[bswap765]], [[byte4]]
; CHECK:  [[bswap76543:%[^ ]+]] = or <2 x i64> [[bswap7654]], [[byte3]]
; CHECK:  [[bswap765432:%[^ ]+]] = or <2 x i64> [[bswap76543]], [[byte2]]
; CHECK:  [[bswap7654321:%[^ ]+]] = or <2 x i64> [[bswap765432]], [[byte1]]
; CHECK:  or <2 x i64> [[bswap7654321]], [[byte0]]

declare <2 x i64> @llvm.bswap.v2i64(<2 x i64>)

define dso_local spir_kernel void @kernel(<2 x i64> %input) {
entry:
  %0 = call <2 x i64> @llvm.bswap.v2i64(<2 x i64> %input)
  ret void
}
