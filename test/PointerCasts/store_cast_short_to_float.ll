; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float %conv to i32
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[cast]], 0
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shr]], 65535
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i32 [[and]] to i16
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float %conv to i32
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[cast]], 16
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shr]], 65535
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i32 [[and]] to i16
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i16, i16 addrspace(1)* %soa, i32 %2
; CHECK: store i16 [[trunc0]], i16 addrspace(1)* [[gep]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add i32 %2, 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i16, i16 addrspace(1)* %soa, i32 [[add1]]
; CHECK: store i16 [[trunc1]], i16 addrspace(1)* [[gep]]
define spir_kernel void @writeToSoaBuffer(i16 addrspace(1)* %soa) {
entry:
  %0 = load i32, i32 addrspace(5)* getelementptr (<3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i32 0, i32 0)
  %mul = mul i32 4, %0
  %1 = sdiv i32 %mul, 4
  %2 = bitcast i16 addrspace(1)* %soa to float addrspace(1)*
  %3 = getelementptr float, float addrspace(1)* %2, i32 %1
  %conv = uitofp i32 %0 to float
  store float %conv, float addrspace(1)* %3, align 4
  ret void
}


