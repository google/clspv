; RUN: clspv-opt --passes=signed-compare-fixup -hack-scf %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <4 x i1> @greater_than(<4 x i32> %x) {
entry:
  %cmp = icmp sgt <4 x i32> %x, <i32 0, i32 1, i32 2, i32 3>
  ret <4 x i1> %cmp
}

; CHECK: [[sub1:%[a-zA-Z0-9_.]+]] = sub <4 x i32> %x, <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[sub2:%[a-zA-Z0-9_.]+]] = sub <4 x i32> [[sub1]], splat (i32 1)
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and <4 x i32> [[sub2]], splat (i32 -2147483648)
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq <4 x i32> [[and]], zeroinitializer
; CHECK: ret <4 x i1> [[cmp]]

