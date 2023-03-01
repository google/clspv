; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(1) %cast, i32 0, i32 0
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[gep]], i32 0
; CHECK: [[gep3:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[gep2]], i32 0
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[gep3]]
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float [[ld]] to i32
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[cast]])
define void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b) {
entry:
  %cast = getelementptr <4 x float>, ptr addrspace(1) %b, i32 0
  %gep = getelementptr i32, ptr addrspace(1) %cast, i32 0
  %ld = load i32, ptr addrspace(1) %gep
  %unpack = call <2 x float> @spirv.unpack.v2f16(i32 %ld)
  ret void
}

declare <2 x float> @spirv.unpack.v2f16(i32)

