
; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(double addrspace(3)* %in, <3 x double> %data, i32 %offset) {
entry:
  call spir_func void @_Z7vstore3Dv3_djPU3AS3d(<3 x double> %data, i32 %offset, double addrspace(3)* %in)
  ret void
}

declare void @_Z7vstore3Dv3_djPU3AS3d(<3 x double>, i32, double addrspace(3)*)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 3
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr double, double addrspace(3)* %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x double> %data, i64 0
; CHECK: store double [[ex]], double addrspace(3)* [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr double, double addrspace(3)* %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x double> %data, i64 1
; CHECK: store double [[ex]], double addrspace(3)* [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr double, double addrspace(3)* %in, i32 [[add]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <3 x double> %data, i64 2
; CHECK: store double [[ex]], double addrspace(3)* [[gep]]
