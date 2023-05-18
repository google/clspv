; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[gep:%[^ ]+]] = getelementptr float, ptr addrspace(1) %out, i32 2
; CHECK:  ptrtoint ptr addrspace(1) [[gep]] to i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 4 %out) {
entry:
  %0 = addrspacecast ptr addrspace(1) %out to ptr addrspace(4)
  %1 = getelementptr float, ptr addrspace(4) %0, i32 2
  %2 = ptrtoint ptr addrspace(4) %1 to i32
  ret void
}
