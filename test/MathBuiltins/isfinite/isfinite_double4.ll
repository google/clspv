; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(<4 x double> %val, <4 x i32> addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func <4 x i32> @_Z8isfiniteDv4_d(<4 x double> %val)
  ;CHECK: %0 = bitcast <4 x double> %val to <4 x i64>
  ;CHECK: %1 = and <4 x i64> <i64 9218868437227405312, i64 9218868437227405312, i64 9218868437227405312, i64 9218868437227405312>, %0
  ;CHECK: %2 = icmp eq <4 x i64> %1, <i64 9218868437227405312, i64 9218868437227405312, i64 9218868437227405312, i64 9218868437227405312>
  ;CHECK: %3 = select <4 x i1> %2, <4 x i32> zeroinitializer, <4 x i32> <i32 -1, i32 -1, i32 -1, i32 -1>
  store <4 x i32> %call, <4 x i32> addrspace(1)* %out, align 8
  ret void
}

declare spir_func <4 x i32> @_Z8isfiniteDv4_d(<4 x double>)

