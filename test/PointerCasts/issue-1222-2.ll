; RUN: clspv-opt --passes=replace-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) %in, align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 8
; CHECK:  store i32 [[load]], ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in, i32 %n) {
entry:
  %load = load i32, ptr addrspace(1) %in, align 4
  %gep = getelementptr [16 x i8], ptr addrspace(1) %in, i32 2
  store i32 %load, ptr addrspace(1) %gep, align 4
  ret void
}

