; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[shl]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i64>, ptr addrspace(1) %0, i32 [[lshr]], i32 [[and]]
; CHECK:  [[load0:%[^ ]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i64>, ptr addrspace(1) %0, i32 [[lshr]], i32 [[add]]
; CHECK:  [[load1:%[^ ]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast i64 [[load0]] to <4 x half>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast i64 [[load1]] to <4 x half>
; CHECK:  [[extract0:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 0
; CHECK:  [[extract1:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 1
; CHECK:  [[extract2:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 2
; CHECK:  [[extract3:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 3
; CHECK:  [[extract4:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 0
; CHECK:  [[extract5:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 1
; CHECK:  [[extract6:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 2
; CHECK:  [[extract7:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 3
; CHECK:  [[insert0:%[^ ]+]] = insertvalue [8 x half] poison, half [[extract0]], 0
; CHECK:  [[insert1:%[^ ]+]] = insertvalue [8 x half] [[insert0]], half [[extract1]], 1
; CHECK:  [[insert2:%[^ ]+]] = insertvalue [8 x half] [[insert1]], half [[extract2]], 2
; CHECK:  [[insert3:%[^ ]+]] = insertvalue [8 x half] [[insert2]], half [[extract3]], 3
; CHECK:  [[insert4:%[^ ]+]] = insertvalue [8 x half] [[insert3]], half [[extract4]], 4
; CHECK:  [[insert5:%[^ ]+]] = insertvalue [8 x half] [[insert4]], half [[extract5]], 5
; CHECK:  [[insert6:%[^ ]+]] = insertvalue [8 x half] [[insert5]], half [[extract6]], 6
; CHECK:  insertvalue [8 x half] [[insert6]], half [[extract7]], 7

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <4 x i64>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds [8 x half], ptr addrspace(1) %0, i32 %i
  %1 = load [8 x half], ptr addrspace(1) %arrayidx, align 8
  store [8 x half] %1, ptr addrspace(1) %a, align 8
  ret void
}


