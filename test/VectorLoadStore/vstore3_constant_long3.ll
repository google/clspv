
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(2) %in, <3 x i64> %data, i32 %offset) {
entry:
  call spir_func void @_Z7vstore3Dv3_mjPU3AS2m(<3 x i64> %data, i32 %offset, ptr addrspace(2) %in)
  ret void
}

declare void @_Z7vstore3Dv3_mjPU3AS2m(<3 x i64>, i32, ptr addrspace(2))

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 3
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(2) %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x i64> %data, i64 0
; CHECK: store i64 [[ex]], ptr addrspace(2) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(2) %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x i64> %data, i64 1
; CHECK: store i64 [[ex]], ptr addrspace(2) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, ptr addrspace(2) %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x i64> %data, i64 2
; CHECK: store i64 [[ex]], ptr addrspace(2) [[gep]]
