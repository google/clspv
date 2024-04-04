; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: atomicrmw umax ptr addrspace(1) %ptr, i32 %f seq_cst, align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) align 4 %out, ptr addrspace(1) align 4 %ptr, i32 %f){
entry:
  %0 = addrspacecast ptr addrspace(1) %ptr to ptr addrspace(4)
  %1 = atomicrmw umax ptr addrspace(4) %0, i32 %f seq_cst, align 4
  store i32 %1, ptr addrspace(1) %out, align 4
  ret void
}
