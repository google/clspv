; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <4 x float> %ld to <4 x i32>
; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i32> [[cast]], <4 x i32> undef, <2 x i32> <i32 0, i32 1>
; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i32> [[cast]], <4 x i32> undef, <2 x i32> <i32 2, i32 3>
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %a, i32 0
; CHECK: store <2 x i32> [[shuffle0]], <2 x i32> addrspace(1)* [[gep]]
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* %a, i32 1
; CHECK: store <2 x i32> [[shuffle1]], <2 x i32> addrspace(1)* [[gep]]
define spir_kernel void @foo(<2 x i32> addrspace(1)* %a, <4 x float> addrspace(1)* %b) {
entry:
  %ld = load <4 x float>, <4 x float> addrspace(1)* %b, align 16
  %cast = bitcast <2 x i32> addrspace(1)* %a to <4 x float> addrspace(1)*
  store <4 x float> %ld, <4 x float> addrspace(1)* %cast, align 16
  ret void
}
