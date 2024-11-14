; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK:  [[byte3:%[^ ]+]] = shl <2 x i32> %input, splat (i32 24)
; CHECK:  [[and:%[^ ]+]] = and <2 x i32> %input, splat (i32 65280)
; CHECK:  [[byte2:%[^ ]+]] = shl <2 x i32> [[and]], splat (i32 8)
; CHECK:  [[lshr:%[^ ]+]] = lshr <2 x i32> %input, splat (i32 8)
; CHECK:  [[byte1:%[^ ]+]] = and <2 x i32> [[lshr]], splat (i32 65280)
; CHECK:  [[byte0:%[^ ]+]] = lshr <2 x i32> %input, splat (i32 24)
; CHECK:  [[bswap32:%[^ ]+]] = or <2 x i32> [[byte3]], [[byte2]]
; CHECK:  [[bswap321:%[^ ]+]] = or <2 x i32> [[bswap32]], [[byte1]]
; CHECK:  or <2 x i32> [[bswap321]], [[byte0]]

declare <2 x i32> @llvm.bswap.v2i32(<2 x i32>)

define dso_local spir_kernel void @kernel(<2 x i32> %input) {
entry:
  %0 = call <2 x i32> @llvm.bswap.v2i32(<2 x i32> %input)
  ret void
}
