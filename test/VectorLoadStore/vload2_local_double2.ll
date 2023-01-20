
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(3) %in, i32 %offset) {
entry:
  %0 = call spir_func <2 x double> @_Z6vload2Dv2_jPU3AS3d(i32 %offset, ptr addrspace(3) %in)
  ret void
}

declare <2 x double> @_Z6vload2Dv2_jPU3AS3d(i32, ptr addrspace(3))

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 %offset, 2
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr double, ptr addrspace(3) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load double, ptr addrspace(3) [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x double> undef, double [[ld]], i64 0
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[mul]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr double, ptr addrspace(3) %in, i32 [[add]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load double, ptr addrspace(3) [[gep]]
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x double> [[in0]], double [[ld]], i64 1
