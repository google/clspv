
; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(float addrspace(2)* %in, i32 %offset) {
entry:
  %0 = call spir_func <4 x float> @_Z6vload4Dv4_jPU3AS2f(i32 %offset, float addrspace(2)* %in)
  ret void
}

declare <4 x float> @_Z6vload4Dv4_jPU3AS2f(i32, float addrspace(2)*)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 4
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load float, float addrspace(2)* [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> undef, float [[ld]], i64 0
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load float, float addrspace(2)* [[gep]]
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[ld]], i64 1
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load float, float addrspace(2)* [[gep]]
; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[ld]], i64 2
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load float, float addrspace(2)* [[gep]]
; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[ld]], i64 3
