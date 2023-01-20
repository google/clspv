
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %in, i32 %offset) {
entry:
  %0 = call spir_func <4 x i64> @_Z6vload4Dv4_jPU3AS1m(i32 %offset, ptr addrspace(1) %in)
  ret void
}

declare <4 x i64> @_Z6vload4Dv4_jPU3AS1m(i32, ptr addrspace(1))

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 4
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(1) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> undef, i64 [[ld]], i64 0
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(1) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in0]], i64 [[ld]], i64 1
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(1) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in1]], i64 [[ld]], i64 2
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(1) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in2]], i64 [[ld]], i64 3
