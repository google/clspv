; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x float>, ptr addrspace(1) %b, i32 0
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load <2 x float>, ptr addrspace(1) [[gep]]
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x float>, ptr addrspace(1) %b, i32 1
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load <2 x float>, ptr addrspace(1) [[gep]]
; CHECK: [[shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <2 x float> [[ld0]], <2 x float> [[ld1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: bitcast <4 x float> [[shuffle]] to <4 x i32>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 16 %a) {
entry:
  %res = call ptr addrspace(1) @clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <2 x float>] } zeroinitializer)
  %b = getelementptr { [0 x <2 x float>] }, ptr addrspace(1) %res, i32 0, i32 0, i32 0
  %0 = load <4 x i32>, ptr addrspace(1) %b, align 16
  store <4 x i32> %0,  ptr addrspace(1) %a, align 16
  ret void
}

declare ptr addrspace(1) @clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x float>] })
