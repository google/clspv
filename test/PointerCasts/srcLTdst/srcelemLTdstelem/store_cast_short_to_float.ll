; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer

; CHECK: [[idx:%[^ ]+]] = shl i32 {{.*}}, 1
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float %conv to <2 x i16>
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 0
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i16, ptr addrspace(1) %soa, i32 [[idx]]
; CHECK: store i16 [[trunc0]], ptr addrspace(1) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[idx]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i16, ptr addrspace(1) %soa, i32 [[add]]
; CHECK: store i16 [[trunc1]], ptr addrspace(1) [[gep]]
define spir_kernel void @writeToSoaBuffer(ptr addrspace(1) %soa) {
entry:
  %0 = load i32, ptr addrspace(5) getelementptr (<3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0)
  %mul = mul i32 4, %0
  %1 = sdiv i32 %mul, 4
  %cast = getelementptr i16, ptr addrspace(1) %soa, i32 0
  %2 = getelementptr float, ptr addrspace(1) %cast, i32 %1
  %conv = uitofp i32 %0 to float
  store float %conv, ptr addrspace(1) %2, align 4
  ret void
}


