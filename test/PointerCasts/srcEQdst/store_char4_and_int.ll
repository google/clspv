; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; CHECK-COUNT-2: store <4 x i8>

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %gep1 = getelementptr i32, ptr addrspace(1) %b, i32 %i
  %loadi8 = load <4 x i8>, ptr addrspace(1) %b, align 4
  %loadi32 = load i32, ptr addrspace(1) %gep1, align 4
  %gep3 = getelementptr <4 x i8>, ptr addrspace(1) %a, i32 %i
  store <4 x i8> %loadi8, ptr addrspace(1) %gep3, align 4
  %gep2 = getelementptr i32, ptr addrspace(1) %a, i32 1
  store i32 %loadi32, ptr addrspace(1) %gep2, align 4
  ret void
}
