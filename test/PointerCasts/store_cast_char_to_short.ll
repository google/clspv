; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[lshr0:%[a-zA-Z0-9_.]+]] = lshr i16 %s, 0
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i16 [[lshr0]] to i8
; CHECK: [[lshr1:%[a-zA-Z0-9_.]+]] = lshr i16 %s, 8
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i16 [[lshr1]] to i8
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr i8, i8 addrspace(1)* %a, i32 0
; CHECK: store i8 [[trunc0]], i8 addrspace(1)* [[gep0]]
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr i8, i8 addrspace(1)* %a, i32 1
; CHECK: store i8 [[trunc1]], i8 addrspace(1)* [[gep1]]
define spir_kernel void @foo(i8 addrspace(1)* %a, i16 %s) {
entry:
  %0 = bitcast i8 addrspace(1)* %a to i16 addrspace(1)*
  %arrayidx = getelementptr inbounds i16, i16 addrspace(1)* %0, i32 0
  store i16 %s, i16 addrspace(1)* %arrayidx, align 2
  ret void
}

