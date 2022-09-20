; RUN: clspv-opt --passes=three-element-vector-lowering -vec3-to-vec4 %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S1 = type <{ <3 x i32>, i32 }>
%struct.S2 = type { <3 x i32>, i32, [12 x i8] }

@test.s1 = internal addrspace(3) global [64 x %struct.S1] undef, align 1
@test.s2 = internal addrspace(3) global [64 x %struct.S2] undef, align 16

; CHECK: %struct.S1 = type <{ <3 x i32>, i32 }>
;
; CHECK: @test.s1 = internal addrspace(3) global [64 x %struct.S1] undef, align 1
; CHECK: @test.s2 = internal addrspace(3) global [64 x { <4 x i32>, i32, [12 x i8] }] undef, align 16
