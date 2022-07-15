; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x float> %0 to <2 x i32>
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i64 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i64 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 0, i32 0
; CHECK: store i32 [[ex0]], ptr addrspace(1) [[gep]]
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 0, i32 1
; CHECK: store i32 [[ex1]], ptr addrspace(1) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 8 %b) {
entry:
  %0 = load <2 x float>, ptr addrspace(1) %b, align 8
  %res = call ptr addrspace(1) @clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %a = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %res, i32 0, i32 0, i32 0
  store <2 x float> %0, ptr addrspace(1) %a, align 8
  ret void
}

declare ptr addrspace(1) @clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })
