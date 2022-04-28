; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[lshr0:%[a-zA-Z0-9_.]+]] = lshr i32 %s, 0
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i32 [[lshr0]] to i16
; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i16 [[trunc0]] to half
; CHECK: [[lshr1:%[a-zA-Z0-9_.]+]] = lshr i32 %s, 16
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i32 [[lshr1]] to i16
; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i16 [[trunc1]] to half
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(1)* %a, i32 0
; CHECK: store half [[cast0]], half addrspace(1)* [[gep0]]
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr half, half addrspace(1)* %a, i32 1
; CHECK: store half [[cast1]], half addrspace(1)* [[gep1]]
define spir_kernel void @foo(half addrspace(1)* %a, i32 %s) {
entry:
  %0 = bitcast half addrspace(1)* %a to i32 addrspace(1)*
  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %0, i32 0
  store i32 %s, i32 addrspace(1)* %arrayidx, align 4
  ret void
}
