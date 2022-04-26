
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(half addrspace(2)* %in, <2 x half> %data, i32 %offset) {
entry:
  call spir_func void @_Z7vstore2Dv2_kDhjPU3AS2kDh(<2 x half> %data, i32 %offset, half addrspace(2)* %in)
  ret void
}

declare void @_Z7vstore2Dv2_kDhjPU3AS2kDh(<2 x half>, i32, half addrspace(2)*)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 2
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(2)* %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> %data, i64 0
; CHECK: store half [[ex]], half addrspace(2)* [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(2)* %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> %data, i64 1
; CHECK: store half [[ex]], half addrspace(2)* [[gep]]
