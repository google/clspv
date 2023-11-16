; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[gep:%[^ ]+]] = getelementptr inbounds i8, ptr addrspace(1) %source, i32 64
; CHECK:  load [124 x i16], ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) %source) {
entry:
  %gep = getelementptr inbounds i8, ptr addrspace(1) %source, i32 64
  %load = load [124 x i16], ptr addrspace(1) %gep, align 4
  ret void
}
