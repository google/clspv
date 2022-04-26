; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(float %val, i32 addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func i32 @_Z8isfinitef(float %val)
  ; CHECK: %0 = bitcast float %val to i32
  ; CHECK: %1 = and i32 2139095040, %0
  ; CHECK: %2 = icmp eq i32 %1, 2139095040
  ; CHECK: %3 = select i1 %2, i32 0, i32 1
  store i32 %call, i32 addrspace(1)* %out, align 4
  ret void
}

declare spir_func i32 @_Z8isfinitef(float)

