
; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(half addrspace(2)* %in, i32 %offset) {
entry:
  %0 = call spir_func <2 x half> @_Z6vload2Dv2_jPU3AS2kDh(i32 %offset, half addrspace(2)* %in)
  ret void
}

declare <2 x half> @_Z6vload2Dv2_jPU3AS2kDh(i32, half addrspace(2)*)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 2
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load half, half addrspace(2)* [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x half> undef, half [[ld]], i64 0
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(2)* %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load half, half addrspace(2)* [[gep]]
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x half> [[in0]], half [[ld]], i64 1
