; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(<2 x float> %val, <2 x i32> addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func <2 x i32> @_Z8isfiniteDv2_f(<2 x float> %val)
  ;CHECK: %0 = bitcast <2 x float> %val to <2 x i32>
  ;CHECK: %1 = and <2 x i32> <i32 2139095040, i32 2139095040>, %0
  ;CHECK: %2 = icmp eq <2 x i32> %1, <i32 2139095040, i32 2139095040>
  ;CHECK: %3 = select <2 x i1> %2, <2 x i32> zeroinitializer, <2 x i32> <i32 -1, i32 -1>
  store <2 x i32> %call, <2 x i32> addrspace(1)* %out, align 8
  ret void
}

; Function Attrs: convergent nounwind readnone
declare spir_func <2 x i32> @_Z8isfiniteDv2_f(<2 x float>)

