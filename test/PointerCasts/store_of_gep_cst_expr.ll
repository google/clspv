; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@test.data = internal addrspace(1) global i32 undef, align 4

define void @foo(i32 %val) {
entry:
    store i32 %val, i32 addrspace(1)* getelementptr (i32, i32 addrspace(1)* @test.data, i32 4), align 4
    ret void
}

; CHECK: %0 = getelementptr i32, i32 addrspace(1)* @test.data, i32 4
