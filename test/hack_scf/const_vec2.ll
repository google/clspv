; RUN: clspv-opt --hack-scf -SignedCompareFixupPass %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(<2 x i32> %x) {
entry:
  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub <2 x i32> %x, <i32 4, i32 4>
  ; CHECK: [[sub2:%[a-zA-Z0-9_]+]] = sub <2 x i32> [[sub]], <i32 1, i32 1>
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and <2 x i32> [[sub2]], <i32 -2147483648, i32 -2147483648>
  ; CHECK: icmp eq <2 x i32> [[and]], zeroinitializer
  %sgt = icmp sgt <2 x i32> %x, <i32 4, i32 4>

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub <2 x i32> %x, <i32 6, i32 6>
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and <2 x i32> [[sub]], <i32 -2147483648, i32 -2147483648>
  ; CHECK: icmp eq <2 x i32> [[and]], zeroinitializer
  %sge = icmp sge <2 x i32> %x, <i32 6, i32 6>

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub <2 x i32> <i32 8, i32 8>, %x
  ; CHECK: [[sub2:%[a-zA-Z0-9_]+]] = sub <2 x i32> [[sub]], <i32 1, i32 1>
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and <2 x i32> [[sub2]], <i32 -2147483648, i32 -2147483648>
  ; CHECK: icmp eq <2 x i32> [[and]], zeroinitializer
  %slt = icmp slt <2 x i32> %x, <i32 8, i32 8>

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub <2 x i32> <i32 10, i32 10>, %x
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and <2 x i32> [[sub]], <i32 -2147483648, i32 -2147483648>
  ; CHECK: icmp eq <2 x i32> [[and]], zeroinitializer
  %sle = icmp sle <2 x i32> %x, <i32 10, i32 10>

  ret void
}

