; RUN: clspv -x ir %s -o %t
; RUN: spirv-val %t
; RUN: spirv-dis -o %t2 %t
; RUN: FileCheck %s < %t2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
; CHECK-DAG: %[[INT8_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 8 0
; CHECK-DAG: %[[INT16_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
; CHECK-DAG: %[[INT32_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
; CHECK-DAG: %[[INT64_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 64 0

define spir_kernel void @umax_i8(i8 addrspace(1)* %out, i8 %a, i8 %b) {
entry:
  %result = call i8 @llvm.umax.i8(i8 %a, i8 %b)
  store i8 %result, i8 addrspace(1)* %out
  ret void
}
declare i8 @llvm.umax.i8(i8, i8)
; CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[INT8_TYPE_ID]] %[[EXT_INST]] UMax
; CHECK: OpStore {{.*}} %[[OP_ID]]


define spir_kernel void @umax_i16(i16 addrspace(1)* %out, i16 %a, i16 %b) {
entry:
  %result = call i16 @llvm.umax.i16(i16 %a, i16 %b)
  store i16 %result, i16 addrspace(1)* %out
  ret void
}
declare i16 @llvm.umax.i16(i16, i16)
; CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[INT16_TYPE_ID]] %[[EXT_INST]] UMax
; CHECK: OpStore {{.*}} %[[OP_ID]]


define spir_kernel void @umax_i32(i32 addrspace(1)* %out, i32 %a, i32 %b) {
entry:
  %result = call i32 @llvm.umax.i32(i32 %a, i32 %b)
  store i32 %result, i32 addrspace(1)* %out
  ret void
}
declare i32 @llvm.umax.i32(i32, i32)
; CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[INT32_TYPE_ID]] %[[EXT_INST]] UMax
; CHECK: OpStore {{.*}} %[[OP_ID]]


define spir_kernel void @umax_i64(i64 addrspace(1)* %out, i64 %a, i64 %b) {
entry:
  %result = call i64 @llvm.umax.i64(i64 %a, i64 %b)
  store i64 %result, i64 addrspace(1)* %out
  ret void
}
declare i64 @llvm.umax.i64(i64, i64)
; CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[INT64_TYPE_ID]] %[[EXT_INST]] UMax
; CHECK: OpStore {{.*}} %[[OP_ID]]
