; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[extract0:%[^ ]+]] = extractvalue [8 x i32] %0, 0
; CHECK: [[extract1:%[^ ]+]] = extractvalue [8 x i32] %0, 1
; CHECK: [[extract2:%[^ ]+]] = extractvalue [8 x i32] %0, 2
; CHECK: [[extract3:%[^ ]+]] = extractvalue [8 x i32] %0, 3
; CHECK: [[extract4:%[^ ]+]] = extractvalue [8 x i32] %0, 4
; CHECK: [[extract5:%[^ ]+]] = extractvalue [8 x i32] %0, 5
; CHECK: [[extract6:%[^ ]+]] = extractvalue [8 x i32] %0, 6
; CHECK: [[extract7:%[^ ]+]] = extractvalue [8 x i32] %0, 7

; CHECK: [[bitcast0:%[^ ]+]] = bitcast i32 [[extract0]] to <2 x half>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast i32 [[extract1]] to <2 x half>
; CHECK: [[bitcast2:%[^ ]+]] = bitcast i32 [[extract2]] to <2 x half>
; CHECK: [[bitcast3:%[^ ]+]] = bitcast i32 [[extract3]] to <2 x half>
; CHECK: [[bitcast4:%[^ ]+]] = bitcast i32 [[extract4]] to <2 x half>
; CHECK: [[bitcast5:%[^ ]+]] = bitcast i32 [[extract5]] to <2 x half>
; CHECK: [[bitcast6:%[^ ]+]] = bitcast i32 [[extract6]] to <2 x half>
; CHECK: [[bitcast7:%[^ ]+]] = bitcast i32 [[extract7]] to <2 x half>

; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[shr]]
; CHECK: store <2 x half> [[bitcast0]], ptr addrspace(1) [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add]]
; CHECK: store <2 x half> [[bitcast1]], ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add2]]
; CHECK: store <2 x half> [[bitcast2]], ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add3]]
; CHECK: store <2 x half> [[bitcast3]], ptr addrspace(1) [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add4]]
; CHECK: store <2 x half> [[bitcast4]], ptr addrspace(1) [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add5]]
; CHECK: store <2 x half> [[bitcast5]], ptr addrspace(1) [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add6]]
; CHECK: store <2 x half> [[bitcast6]], ptr addrspace(1) [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add7]]
; CHECK: store <2 x half> [[bitcast7]], ptr addrspace(1) [[gep]]


define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load [8 x i32], ptr addrspace(1) %b, align 8
  %1 = getelementptr <2 x half>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x i32], ptr addrspace(1) %1, i32 %i
  store [8 x i32] %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

