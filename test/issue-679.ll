; RUN: clspv-opt --passes=three-element-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %out, ptr addrspace(1) %in, i32 %n) {
entry:
    %gep = getelementptr float, ptr addrspace(1) %in, i32 %n
    %load = load float, ptr addrspace(1) %gep, align 4
    store float %load, ptr addrspace(1) %out, align 4
    ret void
}

; CHECK: define spir_kernel void @test(ptr addrspace(1) %out, ptr addrspace(1) %in, i32 %n) {
; CHECK: [[gep:%[^ ]+]] = getelementptr float, ptr addrspace(1) %in, i32 %n
; CHECK: [[load:%[^ ]+]] = load float, ptr addrspace(1) [[gep]], align 4
; CHECK: store float [[load]], ptr addrspace(1) %out, align 4

