; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: [[shl:%[^ ]+]] = shl <2 x i16> %input, splat (i16 8)
; CHECK: [[lshr:%[^ ]+]] = lshr <2 x i16> %input, splat (i16 8)
; CHECK: or <2 x i16> [[shl]], [[lshr]]

declare <2 x i16> @llvm.bswap.v2i16(<2 x i16>)

define dso_local spir_kernel void @kernel(<2 x i16> %input) {
entry:
  %0 = call <2 x i16> @llvm.bswap.v2i16(<2 x i16> %input)
  ret void
}
