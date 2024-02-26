; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %a, i32 %i) {
entry:
; CHECK: entry
; CHECK-NEXT: [[shl0:%[^ ]+]] = shl i32 %i, 2
; CHECK-NEXT: [[shl1:%[^ ]+]] = shl i32 [[shl0]], 2
; CHECK-NEXT: [[add:%[^ ]+]] = add i32 [[shl1]], 8
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %a, i32 [[add]]
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i, i32 2
  br label %end

block:
; CHECK: [[gepblock:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %a, i32 %i
  %1 = getelementptr i8, ptr addrspace(1) %a, i32 %i
  br label %end

end:
; CHECK: phi ptr addrspace(1) [ [[gep]], %entry ], [ [[gepblock]], %block ]
  %phi = phi ptr addrspace(1) [ %0, %entry ], [ %1, %block ]
  %gep = getelementptr i8, ptr addrspace(1) %phi, i32 7
  ret void
}

define spir_kernel void @test2(ptr addrspace(1) %a, i32 %i) {
entry:
; CHECK: entry
; CHECK-NEXT: [[shl0:%[^ ]+]] = shl i32 %i, 2
; CHECK-NEXT: [[shl1:%[^ ]+]] = shl i32 [[shl0]], 2
; CHECK-NEXT: [[add:%[^ ]+]] = add i32 [[shl1]], 8
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %a, i32 [[add]]
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i, i32 2
  br label %end

block:
; CHECK: block
; CHECK-NEXT: [[gepblock:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %a, i32 %i
  %1 = getelementptr i8, ptr addrspace(1) %a, i32 %i
  br label %end

end:
; CHECK: phi ptr addrspace(1) [ [[gep]], %entry ], [ [[gepblock]], %block ]
  %phi = phi ptr addrspace(1) [ %0, %entry ], [ %1, %block ]
  %gep = getelementptr i16, ptr addrspace(1) %phi, i32 7
  ret void
}

define spir_kernel void @test3(ptr addrspace(1) %a, i32 %i) {
entry:
; CHECK: entry
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i
  br label %end

block:
; CHECK: block
; CHECK-NEXT: [[gepblock:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i, i32 1
  %1 = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %i, i32 1
  br label %end

end:
; CHECK: phi ptr addrspace(1) [ [[gep]], %entry ], [ [[gepblock]], %block ]
  %phi = phi ptr addrspace(1) [ %0, %entry ], [ %1, %block ]
  %gep = getelementptr i32, ptr addrspace(1) %phi, i32 7
  ret void
}

define spir_kernel void @test4(i1 %cmp, i32 %offset, ptr addrspace(1) %a) {
entry:
; CHECK: entry
; CHECK-NEXT: br label %pre
  %gep = getelementptr inbounds i8, ptr addrspace(1) %a, i32 %offset
  br label %pre
pre:
; CHECK: pre
; CHECK-NEXT: [[shl:%[^ ]+]] = shl i32 %offset, 3
; CHECK-NEXT: [[add:%[^ ]+]] = add i32 %offset, [[shl]]
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %a, i32 %1
; CHECK-NEXT: br label %loop
  %gep2 = getelementptr inbounds <4 x half>, ptr addrspace(1) %gep, i32 %offset
  br label %loop
loop:
; CHECK: loop
; CHECK-NEXT: phi ptr addrspace(1) [ [[gep]], %pre ]
  %phi = phi ptr addrspace(1) [ %gep2, %pre ], [ %add, %loop ]
  %load = load <4 x half>, ptr addrspace(1) %phi, align 8
  %add = getelementptr inbounds i8, ptr addrspace(1) %phi, i32 64
  br i1 %cmp, label %loop, label %exit
exit:
  ret void
}
