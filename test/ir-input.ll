; RUN: clspv -x ir %s -o %t
; RUN: spirv-val %t
; RUN: spirv-dis -o %t2 %t
; RUN: FileCheck %s < %t2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(i32 addrspace(1)* %out) {
entry:
  %out.addr = alloca i32 addrspace(1)*, align 4
  store i32 addrspace(1)* %out, i32 addrspace(1)** %out.addr, align 4
  %0 = load i32 addrspace(1)*, i32 addrspace(1)** %out.addr, align 4
  store i32 42, i32 addrspace(1)* %0, align 4
  ret void
}

; CHECK: %uint = OpTypeInt 32 0
; CHECK: %uint_42 = OpConstant %uint 42
; CHECK: OpStore {{.*}} %uint_42

