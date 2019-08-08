; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 0
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <4 x float>, <4 x float> addrspace(1)* [[gep]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> [[ld]], i32 0
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast float [[ex]] to i32
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[cast]])
define void @foo(<4 x float> addrspace(1)* %a, <4 x float> addrspace(1)* %b) {
entry:
  %cast = bitcast <4 x float> addrspace(1)* %b to i32 addrspace(1)*
  %gep = getelementptr i32, i32 addrspace(1)* %cast, i32 0
  %ld = load i32, i32 addrspace(1)* %gep
  %unpack = call <2 x float> @spirv.unpack.v2f16(i32 %ld)
  ret void
}

declare <2 x float> @spirv.unpack.v2f16(i32)
