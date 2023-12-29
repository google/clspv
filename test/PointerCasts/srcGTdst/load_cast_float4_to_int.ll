; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(1) %b, i32 0, i32 3
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[gep]], i32 0
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[gep2]]
; CHECK: bitcast float [[ld0]] to i32
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b) {
entry:
  %0 = getelementptr <4 x float>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %0, i32 3
  %1 = load i32, ptr addrspace(1) %arrayidx, align 8
  store i32 %1, ptr addrspace(1) %a, align 8
  ret void
}



