; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <4 x float> %ld to <4 x i32>
; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i32> [[cast]], <4 x i32> poison, <2 x i32> <i32 0, i32 1>
; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i32> [[cast]], <4 x i32> poison, <2 x i32> <i32 2, i32 3>
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, ptr addrspace(1) %a, i32 0
; CHECK: store <2 x i32> [[shuffle0]], ptr addrspace(1) [[gep]]
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, ptr addrspace(1) %a, i32 1
; CHECK: store <2 x i32> [[shuffle1]], ptr addrspace(1) [[gep]]

define spir_kernel void @foo(ptr addrspace(1) %b) {
entry:
  %ld = load <4 x float>, ptr addrspace(1) %b, align 16
  %res = call ptr addrspace(1) @clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <2 x i32>] } zeroinitializer)
  %a = getelementptr { [0 x <2 x i32>] }, ptr addrspace(1) %res, i32 0, i32 0, i32 0
  store <4 x float> %ld, ptr addrspace(1) %a, align 16
  ret void
}

declare ptr addrspace(1) @clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x i32>] })
