; RUN: clspv-opt --hack-scf -SignedCompareFixupPass %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(i32 %x) {
entry:
  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub i32 4, %x
  ; CHECK: [[sub2:%[a-zA-Z0-9_]+]] = sub i32 [[sub]], 1
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 [[sub2]], -2147483648
  ; CHECK: icmp eq i32 [[and]], 0
  %sgt = icmp sgt i32 4, %x

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub i32 6, %x
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 [[sub]], -2147483648
  ; CHECK: icmp eq i32 [[and]], 0
  %sge = icmp sge i32 6, %x

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub i32 %x, 8
  ; CHECK: [[sub2:%[a-zA-Z0-9_]+]] = sub i32 [[sub]], 1
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 [[sub2]], -2147483648
  ; CHECK: icmp eq i32 [[and]], 0
  %slt = icmp slt i32 8, %x

  ; CHECK: [[sub:%[a-zA-Z0-9_]+]] = sub i32 %x, 10
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 [[sub]], -2147483648
  ; CHECK: icmp eq i32 [[and]], 0
  %sle = icmp sle i32 10, %x

  ret void
}
