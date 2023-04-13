; RUN: clspv-opt --passes=spirv-producer -o %t.out.ll -producer-out-file %t.spv -spv-version=1.6 %s
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env spv1.6 %t.spv


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0{{$}}

; CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
; CHECK-DAG: [[ushort0:%[^ ]+]] = OpConstant [[ushort]] 0{{$}}

; CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
; CHECK-DAG: [[ulong0:%[^ ]+]] = OpConstant [[ulong]] 0{{$}}

; CHECK-DAG: OpBitReverse [[uint]] [[uint0]]
; CHECK-DAG: OpBitReverse [[ushort]] [[ushort0]]
; CHECK-DAG: OpBitReverse [[ulong]] [[ulong0]]

define dso_local spir_kernel void @kernel32() {
entry:
  %bitreverse = tail call i32 @llvm.bitreverse.i32(i32 0)
  ret void
}

define dso_local spir_kernel void @kernel16() {
entry:
  %bitreverse = tail call i16 @llvm.bitreverse.i16(i16 0)
  ret void
}

define dso_local spir_kernel void @kernel64() {
entry:
  %bitreverse = tail call i64 @llvm.bitreverse.i64(i64 0)
  ret void
}

declare i32 @llvm.bitreverse.i32(i32) #1
declare i16 @llvm.bitreverse.i16(i16) #1
declare i64 @llvm.bitreverse.i64(i64) #1
