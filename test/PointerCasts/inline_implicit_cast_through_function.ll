; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-pointer-cast-arg
; RUN: FileCheck %s < %t.ll

; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-pointer-cast-arg -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t.ll

; CHECK-NOT: call void @bar

; UNTYPED: call void @bar

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s = type { [32 x float] }

define void @bar(ptr addrspace(1) %p1, ptr addrspace(1) %p2) {
entry:
  %gep1 = getelementptr %s, ptr addrspace(1) %p1, i32 0, i32 0, i32 1
  %ld = load float, ptr addrspace(1) %p2
  ret void
}

define void @foo(ptr addrspace(1) %p) {
entry:
  call void @bar(ptr addrspace(1) %p, ptr addrspace(1) %p)
  ret void
}

