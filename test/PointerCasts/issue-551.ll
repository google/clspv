; RUN: clspv-opt -ReplacePointerBitcast %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(i8 addrspace(1)* %in, i16 addrspace(1)* %out) {
entry:
  %0 = bitcast i8 addrspace(1)* %in to i16 addrspace(1)*
  %1 = load i16, i16 addrspace(1)* %0, align 2
  store i16 %1, i16 addrspace(1)* %out, align 2
  ; CHECK: [[gep1:%[a-zA-Z0-9_]+]] = getelementptr i8, i8 addrspace(1)* %in, i32 0
  ; CHECK: [[val1:%[a-zA-Z0-9_]+]] = load i8, i8 addrspace(1)* [[gep1]]
  ; CHECK: [[gep2:%[a-zA-Z0-9_]+]] = getelementptr i8, i8 addrspace(1)* %in, i32 1
  ; CHECK: [[val2:%[a-zA-Z0-9_]+]] = load i8, i8 addrspace(1)* [[gep2]]
  ; CHECK: [[extval1:%[a-zA-Z0-9_]+]] = zext i8 [[val1]] to i16
  ; CHECK: [[extval2:%[a-zA-Z0-9_]+]] = zext i8 [[val2]] to i16
  ; CHECK: [[shiftedval2:%[a-zA-Z0-9_]+]] = shl i16 [[extval2]], 8
  ; CHECK: [[combinedval:%[a-zA-Z0-9_]+]] = or i16 [[extval1]], [[shiftedval2]]
  ; CHECK: store i16 [[combinedval]], i16 addrspace(1)* %out, align 2
  ret void
}
