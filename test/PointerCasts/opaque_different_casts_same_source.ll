; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: block1:
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %x, 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[shl]]
; CHECK: load i32, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[add]]
; CHECK: load i32, ptr addrspace(1) [[gep]]

; CHECK: block2:
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %y, 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[shl]]
; CHECK: load i32, ptr addrspace(1) [[gep]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[add1]]
; CHECK: load i32, ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = add i32 [[add1]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[add2]]
; CHECK: load i32, ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, ptr addrspace(1) %base_gep, i32 [[add3]]
; CHECK: load i32, ptr addrspace(1) [[gep]]
; CHECK: bitcast <4 x i32> %{{.*}} to <4 x float>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(ptr addrspace(1) %in, i32 %n, i32 %x, i32 %y) {
entry:
  %base_gep = getelementptr i32, ptr addrspace(1) %in, i32 %n
  br label %block1

block1:
  %gep1 = getelementptr <2 x i32>, ptr addrspace(1) %base_gep, i32 %x
  %ld1 = load <2 x i32>, ptr addrspace(1) %gep1
  br label %block2

block2:
  %gep2 = getelementptr <4 x float>, ptr addrspace(1) %base_gep, i32 %y
  %ld2 = load <4 x float>, ptr addrspace(1) %gep2
  ret void
}
