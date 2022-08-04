; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@test.data = internal addrspace(1) global float undef, align 4

define void @foo() {
entry:
    %0 = load i32, i32 addrspace(1)* getelementptr (i32, i32 addrspace(1)* bitcast (float addrspace(1)* @test.data to i32 addrspace(1)*), i32 4), align 4
    ret void
}

; CHECK: [[bitcast:%[^ ]+]] = bitcast float addrspace(1)* @test.data to i32 addrspace(1)*
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, i32 addrspace(1)* [[bitcast]], i32 4
; CHECK: load i32, i32 addrspace(1)* [[gep]]
