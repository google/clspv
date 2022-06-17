; RUN: clspv-opt %s -o %t.ll --passes=specialize-image-types

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in, i32 %n) {
entry:
  br label %loop

loop:
  %phi = phi ptr addrspace(1) [ %in, %entry ], [ %p1, %next ]
  %cmp = icmp eq i32 %n, 0
  br i1 %cmp, label %next, label %exit

next:
  %p1 = getelementptr i32, ptr addrspace(1) %phi, i32 1
  br label %loop

exit:
  ret void
}

