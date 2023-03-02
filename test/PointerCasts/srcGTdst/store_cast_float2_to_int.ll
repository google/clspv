; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 %0 to float
; CHECK-DAG: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x float>, ptr addrspace(1) %1, i32 0, i32 0
; CHECK-DAG: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[gep]], i32 %i
; CHECK-DAG: [[gep3:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[gep2]], i32 0
; CHECK: store float [[cast]], ptr addrspace(1) [[gep3]]
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load i32, ptr addrspace(1) %b, align 4
  %1 = getelementptr <2 x float>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %1, i32 %i
  store i32 %0, ptr addrspace(1) %arrayidx, align 4
  ret void
}


