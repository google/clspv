; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t.ll

; CHECK: [[gep:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
; CHECK: [[lshr:%[^ ]+]] = lshr i32 %i, 2
; CHECK: [[and:%[^ ]+]] = and i32 %i, 3
; CHECK: getelementptr <4 x i32>, ptr addrspace(1) %a, i32 [[lshr]], i32 [[and]]

; UNTYPED: getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
; UNTYPED: getelementptr i32, ptr addrspace(1) %a, i32 %i

define spir_kernel void @test(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
  %1 = getelementptr i32, ptr addrspace(1) %a, i32 %i
  ret void
}
