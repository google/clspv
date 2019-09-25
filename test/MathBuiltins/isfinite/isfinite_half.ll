; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(half %val, i32 addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func i32 @_Z8isfiniteh(half %val)
  ; CHECK: %0 = bitcast half %val to i16
  ; CHECK: %1 = and i16 31744, %0
  ; CHECK: %2 = icmp eq i16 %1, 31744
  ; CHECK: %3 = select i1 %2, i32 0, i32 1
  store i32 %call, i32 addrspace(1)* %out, align 4
  ret void
}

declare spir_func i32 @_Z8isfiniteh(half)

