; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  %0 = bitcast [1536 x i8] addrspace(3)* @test.data to i32 addrspace(3)*

@test.data = internal addrspace(3) global [1536 x i8] undef, align 8

define void @foo() {
entry:
  %0 = bitcast half addrspace(3)* bitcast ([1536 x i8] addrspace(3)* @test.data to half addrspace(3)*) to i32 addrspace(3)*
  ret void
}
