; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x i32> %b to <2 x float>
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x float> [[cast]], i32 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x float> [[cast]], i32 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %a, i32 0, i32 0
; CHECK: store float [[ex0]], float addrspace(1)* [[gep]]
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %a, i32 0, i32 1
; CHECK: store float [[ex1]], float addrspace(1)* [[gep]]
define void @foo(<4 x float> addrspace(1)* %a, <2 x i32> %b) {
entry:
  %cast = bitcast <4 x float> addrspace(1)* %a to <2 x i32> addrspace(1)*
  %gep = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %cast, i32 0
  store <2 x i32> %b, <2 x i32> addrspace(1)* %gep
  ret void
}

