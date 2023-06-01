; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int
; RUN: FileCheck %s < %t.ll

; We expect a base of 1152921504606846976 (0x1000000000000000) plus an offset
; of 4 x 4 + 4 + 8 * %i = 20 + (%i << 3) => 1152921504606846996 (0x1000000000000014)

; CHECK:  [[shl0:%[^ ]+]] = shl i64 %i, 1
; CHECK:  [[shl1:%[^ ]+]] = shl i64 [[shl0]], 2
; CHECK:  [[add:%[^ ]+]] = add i64 1152921504606846996, [[shl1]]
; CHECK:  store i64 [[add]], ptr %dst, align 4

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define dso_local spir_kernel void @foo(ptr %dst, i64 %i) {
entry:
  %gep = getelementptr i32, ptr %dst, i64 4
  %gep2 = getelementptr <2 x i32>, ptr %gep, i64 %i, i64 1
  %ptrtoint = ptrtoint ptr %gep2 to i64
  store i64 %ptrtoint, ptr %dst, align 4
  ret void
}


