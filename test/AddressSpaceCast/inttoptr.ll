; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[int:%[^ ]+]] = ptrtoint ptr addrspace(1) %out to i32
; CHECK:  [[ptr:%[^ ]+]] = inttoptr i32 [[int]] to ptr addrspace(1)
; CHECK:  getelementptr float, ptr addrspace(1) [[ptr]], i32 2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 4 %out) {
entry:
  %0 = ptrtoint ptr addrspace(1) %out to i32
  %1 = inttoptr i32 %0 to ptr addrspace(4)
  %2 = getelementptr float, ptr addrspace(4) %1, i32 2
  %3 = addrspacecast ptr addrspace(4) %2 to ptr addrspace(1)
  ret void
}
