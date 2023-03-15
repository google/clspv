; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float %conv to <4 x i8>
; CHECK: [[trunc0:%[^ ]+]] = extractelement <4 x i8> [[cast]], i64 0
; CHECK: [[trunc1:%[^ ]+]] = extractelement <4 x i8> [[cast]], i64 1
; CHECK: [[trunc2:%[^ ]+]] = extractelement <4 x i8> [[cast]], i64 2
; CHECK: [[trunc3:%[^ ]+]] = extractelement <4 x i8> [[cast]], i64 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i8, ptr addrspace(1) %cast, i32
; CHECK: store i8 [[trunc0]], ptr addrspace(1) [[gep]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add i32 %{{.*}}, 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i8, ptr addrspace(1) %cast, i32 [[add1]]
; CHECK: store i8 [[trunc1]], ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = add i32 [[add1]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i8, ptr addrspace(1) %cast, i32 [[add2]]
; CHECK: store i8 [[trunc2]], ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i8, ptr addrspace(1) %cast, i32 [[add3]]
; CHECK: store i8 [[trunc3]], ptr addrspace(1) [[gep]]

define spir_kernel void @writeToSoaBuffer(ptr addrspace(1) %soa) {
entry:
  %0 = load i32, ptr addrspace(5) getelementptr (<3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0)
  %mul = mul i32 4, %0
  %1 = sdiv i32 %mul, 4
  %cast = getelementptr i8, ptr addrspace(1) %soa, i32 0
  %2 = getelementptr float, ptr addrspace(1) %cast, i32 %1
  %conv = uitofp i32 %0 to float
  store float %conv, ptr addrspace(1) %2, align 4
  ret void
}

