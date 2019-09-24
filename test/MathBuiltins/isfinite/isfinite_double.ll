; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(double %val, i32 addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func i32 @_Z8isfinited(double %val)
  ; CHECK: %0 = bitcast double %val to i64
  ; CHECK: %1 = and i64 9218868437227405312, %0
  ; CHECK: %2 = icmp eq i64 %1, 9218868437227405312
  ; CHECK: %3 = select i1 %2, i32 0, i32 1
  store i32 %call, i32 addrspace(1)* %out, align 4
  ret void
}

declare spir_func i32 @_Z8isfinited(double)

