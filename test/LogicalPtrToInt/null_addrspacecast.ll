; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int --physical-storage-buffers
; RUN: FileCheck %s < %t.ll

; CHECK: [[cmp:%[^ ]+]] = icmp ne i64 %val, 0
; CHECK: store i1 [[cmp]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 1 %a, i64 %val) {
entry:
  %addrspacecast = addrspacecast ptr addrspace(4) null to ptr addrspace(1)
  %ptrtoint = ptrtoint ptr addrspace(1) %addrspacecast to i64
  %cmp = icmp ne i64 %val, %ptrtoint
  store i1 %cmp, ptr addrspace(1) %a, align 4
  ret void
}
