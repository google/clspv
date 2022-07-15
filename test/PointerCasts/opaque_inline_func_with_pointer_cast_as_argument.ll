; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-pointer-cast-arg
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: @foo
; CHECK-NOT call void @bar

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @bar(ptr addrspace(1) %p) {
entry:
  store i32 1, ptr addrspace(1) %p
  ret void
}

define void @foo(ptr addrspace(1) %p, i32 %n) {
entry:
  %gep = getelementptr float, ptr addrspace(1) %p, i32 %n
  call void @bar(ptr addrspace(1) %gep)
  ret void
}
