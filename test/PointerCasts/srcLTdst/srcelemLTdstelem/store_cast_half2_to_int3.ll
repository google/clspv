; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 3
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[extract0:%[^ ]+]] = extractelement <3 x i32> %0, i64 0
; CHECK: [[extract1:%[^ ]+]] = extractelement <3 x i32> %0, i64 1
; CHECK: [[extract2:%[^ ]+]] = extractelement <3 x i32> %0, i64 2
; CHECK: [[bitcast0:%[^ ]+]] = bitcast i32 [[extract0]] to <2 x half>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast i32 [[extract1]] to <2 x half>
; CHECK: [[bitcast2:%[^ ]+]] = bitcast i32 [[extract2]] to <2 x half>
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[shr]]
; CHECK: store <2 x half> [[bitcast0]], <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add]]
; CHECK: store <2 x half> [[bitcast1]], <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add2]]
; CHECK: store <2 x half> [[bitcast2]], <2 x half> addrspace(1)* [[gep]]
define spir_kernel void @foo(<2 x half> addrspace(1)* %a, <3 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <3 x i32>, <3 x i32> addrspace(1)* %b, align 8
  %1 = bitcast <2 x half> addrspace(1)* %a to <3 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <3 x i32>, <3 x i32> addrspace(1)* %1, i32 %i
  store <3 x i32> %0, <3 x i32> addrspace(1)* %arrayidx, align 8
  ret void
}

