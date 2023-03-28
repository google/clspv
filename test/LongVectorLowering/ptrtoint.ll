; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; CHECK: @test_vec_align_packed_struct.test = internal addrspace(3) global { [8 x i8] } undef, align 1
; CHECK: inttoptr i32 ptrtoint (ptr addrspace(3) @test_vec_align_packed_struct.test to i32) to ptr addrspace(3)


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.myPackedStruct = type { <8 x i8> }

@test_vec_align_packed_struct.test = internal addrspace(3) global %struct.myPackedStruct undef, align 1

define dso_local spir_kernel void @foo() {
entry:
    %0 = ptrtoint ptr addrspace(3) @test_vec_align_packed_struct.test to i32
    %1 = inttoptr i32 %0 to ptr addrspace(3)
    ret void
}
