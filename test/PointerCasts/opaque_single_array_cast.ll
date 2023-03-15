; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [8 x i32], ptr addrspace(2) @global, i32 0, i32 %n
; CHECK: load i32, ptr addrspace(2) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@global = private addrspace(2) constant [8 x i32] zeroinitializer 

define void @foo(ptr addrspace(1) %a, i32 %n) {
entry:
  %gep = getelementptr i32, ptr addrspace(2) @global, i32 %n
  %ld = load i32, ptr addrspace(2) %gep
  store i32 %ld, ptr addrspace(1) %a
  ret void
}

