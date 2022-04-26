; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type <{ <8 x i32>, i32 }>

@test.s = internal addrspace(3) global [64 x %struct.S] undef, align 1

; CHECK: @test.s = internal addrspace(3) global [64 x { [8 x i32], i32 }] undef, align 1
