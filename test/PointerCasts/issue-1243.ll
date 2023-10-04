; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[gep:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i

; TODO (#1243): Wrong simplification! we should have something with the div and mod of %i in the gep indices
; CHECK: getelementptr <4 x i32>, ptr addrspace(1) %a, i32 0, i32 %i

define spir_kernel void @test(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
  %1 = getelementptr i32, ptr addrspace(1) %a, i32 %i
  ret void
}
