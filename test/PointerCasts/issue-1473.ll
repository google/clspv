; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; This test used to involve an infinite loop

; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i32], ptr addrspace(3) @test.x, i32 0
; CHECK-COUNT-8: getelementptr i32, ptr addrspace(3) [[gep]], i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@test.x = internal addrspace(3) global [8 x i32] undef, align 4

define dso_local spir_kernel void @test(ptr addrspace(1) align 32 %output) {
entry:
  %arrayidx1 = getelementptr inbounds <8 x i32>, ptr addrspace(3) @test.x, i32 0
  %0 = load <8 x i32>, ptr addrspace(3) %arrayidx1, align 32
  ret void
}
