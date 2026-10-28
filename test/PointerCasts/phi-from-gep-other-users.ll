; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; %p is loaded as i32 and is the start of a loop over its bytes. The PHI needs
; an i8 GEP while the load needs an i32 GEP.

; CHECK-LABEL: @dynamic_offset
; CHECK: entry:
; CHECK-NEXT: [[off:%[^ ]+]] = shl i32 %i, 2
; CHECK-NEXT: [[c0:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 [[off]]
; CHECK-NEXT: %p = getelementptr i32, ptr addrspace(1) %in, i32 %i
; CHECK-NEXT: %x = load i32, ptr addrspace(1) %p, align 4
; CHECK: %c = phi ptr addrspace(1) [ [[c0]], %entry ], [ %c.next, %loop ]
; CHECK: load i8, ptr addrspace(1) %c, align 1

; CHECK-LABEL: @constant_offset
; CHECK: entry:
; CHECK-NEXT: [[c0:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 4
; CHECK-NEXT: [[p:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %in, i32 1
; CHECK-NEXT: %x = load i32, ptr addrspace(1) [[p]], align 4
; CHECK: %c = phi ptr addrspace(1) [ [[c0]], %entry ], [ %c.next, %loop ]
; CHECK: load i8, ptr addrspace(1) %c, align 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @dynamic_offset(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i, i32 %n) {
entry:
  %p = getelementptr i32, ptr addrspace(1) %in, i32 %i
  %x = load i32, ptr addrspace(1) %p, align 4
  br label %loop

loop:
  %c = phi ptr addrspace(1) [ %p, %entry ], [ %c.next, %loop ]
  %j = phi i32 [ 0, %entry ], [ %j.next, %loop ]
  %s = phi i32 [ %x, %entry ], [ %s.next, %loop ]
  %b = load i8, ptr addrspace(1) %c, align 1
  %b32 = sext i8 %b to i32
  %s.next = add i32 %s, %b32
  %c.next = getelementptr i8, ptr addrspace(1) %c, i32 1
  %j.next = add i32 %j, 1
  %cmp = icmp ult i32 %j.next, %n
  br i1 %cmp, label %loop, label %exit

exit:
  store i32 %s.next, ptr addrspace(1) %out, align 4
  ret void
}

define spir_kernel void @constant_offset(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %n) {
entry:
  %p = getelementptr i8, ptr addrspace(1) %in, i32 4
  %x = load i32, ptr addrspace(1) %p, align 4
  br label %loop

loop:
  %c = phi ptr addrspace(1) [ %p, %entry ], [ %c.next, %loop ]
  %j = phi i32 [ 0, %entry ], [ %j.next, %loop ]
  %s = phi i32 [ %x, %entry ], [ %s.next, %loop ]
  %b = load i8, ptr addrspace(1) %c, align 1
  %b32 = sext i8 %b to i32
  %s.next = add i32 %s, %b32
  %c.next = getelementptr i8, ptr addrspace(1) %c, i32 1
  %j.next = add i32 %j, 1
  %cmp = icmp ult i32 %j.next, %n
  br i1 %cmp, label %loop, label %exit

exit:
  store i32 %s.next, ptr addrspace(1) %out, align 4
  ret void
}
