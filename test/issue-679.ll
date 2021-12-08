; RUN: clspv-opt --ThreeElementVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(float addrspace(1)* %out, <3 x float> addrspace(1)* %in, i32 %n) {
entry:
    %bitcast = bitcast <3 x float> addrspace(1)* %in to float addrspace(1)*
    %gep = getelementptr float, float addrspace(1)* %bitcast, i32 %n
    %load = load float, float addrspace(1)* %gep, align 4
    store float %load, float addrspace(1)* %out, align 4
    ret void
}

; CHECK: define spir_kernel void @test(float addrspace(1)* %out, <4 x float> addrspace(1)* %in, i32 %n) {
; CHECK: [[bitcast:%[^ ]+]] = bitcast <4 x float> addrspace(1)* %in to float addrspace(1)*
; CHECK: [[gep:%[^ ]+]] = getelementptr float, float addrspace(1)* [[bitcast]], i32 %n
; CHECK: [[load:%[^ ]+]] = load float, float addrspace(1)* [[gep]], align 4
; CHECK: store float [[load]], float addrspace(1)* %out, align 4

