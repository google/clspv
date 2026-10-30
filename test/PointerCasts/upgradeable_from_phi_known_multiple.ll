; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; The loop loads i32 through %p, which is advanced by a dynamic number of bytes
; that is a multiple of 4, as InstCombine folds `p += (int)n` on an int
; pointer. The GEPs defining the type of %p must be upgraded to i32 GEPs, using
; an exact arithmetic shift as the offset can be negative.

; CHECK: [[stride:%[^ ]+]] = ashr exact i64 %sext, 30
; CHECK: [[idx0:%[^ ]+]] = ashr exact i64 [[stride]], 2
; CHECK: [[add:%[^ ]+]] = add i64 {{%[^ ]+}}, [[idx0]]
; CHECK: [[p0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %first, i64 [[add]]
; CHECK: loop:
; CHECK: [[p:%[^ ]+]] = phi ptr addrspace(1) [ [[p0]], %entry ], [ [[next:%[^ ]+]], %loop ]
; CHECK: load i32, ptr addrspace(1) [[p]], align 4
; CHECK: [[idx:%[^ ]+]] = ashr exact i64 [[stride]], 2
; CHECK: [[next]] = getelementptr i32, ptr addrspace(1) [[p]], i64 [[idx]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

define spir_kernel void @foo(ptr addrspace(1) %first, ptr addrspace(1) %out, i64 %lid, i64 %n, i64 %count) {
entry:
  %lid_off = shl i64 %lid, 2
  %start = getelementptr i8, ptr addrspace(1) %first, i64 %lid_off
  %v0 = load i32, ptr addrspace(1) %start, align 4
  %sext = shl i64 %n, 32
  %stride = ashr exact i64 %sext, 30
  %p0 = getelementptr i8, ptr addrspace(1) %start, i64 %stride
  br label %loop

loop:
  %p = phi ptr addrspace(1) [ %p0, %entry ], [ %p.next, %loop ]
  %i = phi i64 [ 1, %entry ], [ %i.next, %loop ]
  %sum = phi i32 [ %v0, %entry ], [ %sum.next, %loop ]
  %v = load i32, ptr addrspace(1) %p, align 4
  %sum.next = add i32 %sum, %v
  %p.next = getelementptr i8, ptr addrspace(1) %p, i64 %stride
  %i.next = add i64 %i, 1
  %cmp = icmp ult i64 %i.next, %count
  br i1 %cmp, label %loop, label %exit

exit:
  store i32 %sum.next, ptr addrspace(1) %out, align 4
  ret void
}
