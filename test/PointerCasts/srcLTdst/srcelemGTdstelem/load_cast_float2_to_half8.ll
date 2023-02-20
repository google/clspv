; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x float>, ptr addrspace(1) %0, i32 [[shr]]
; CHECK:  [[ld0:%[^ ]+]] = load <2 x float>, ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x float>, ptr addrspace(1) %0, i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load <2 x float>, ptr addrspace(1) [[gep]]

; CHECK:  [[vec0:%[^ ]+]] = bitcast <2 x float> [[ld0]] to <4 x half>
; CHECK:  [[vec1:%[^ ]+]] = bitcast <2 x float> [[ld1]] to <4 x half>

; CHECK:  [[v0:%[^ ]+]] = extractelement <4 x half> [[vec0]], i64 0
; CHECK:  [[v1:%[^ ]+]] = extractelement <4 x half> [[vec0]], i64 1
; CHECK:  [[v2:%[^ ]+]] = extractelement <4 x half> [[vec0]], i64 2
; CHECK:  [[v3:%[^ ]+]] = extractelement <4 x half> [[vec0]], i64 3
; CHECK:  [[v4:%[^ ]+]] = extractelement <4 x half> [[vec1]], i64 0
; CHECK:  [[v5:%[^ ]+]] = extractelement <4 x half> [[vec1]], i64 1
; CHECK:  [[v6:%[^ ]+]] = extractelement <4 x half> [[vec1]], i64 2
; CHECK:  [[v7:%[^ ]+]] = extractelement <4 x half> [[vec1]], i64 3

; CHECK:  [[ret0:%[^ ]+]] = insertvalue [8 x half] poison, half [[v0]], 0
; CHECK:  [[ret1:%[^ ]+]] = insertvalue [8 x half] [[ret0]], half [[v1]], 1
; CHECK:  [[ret2:%[^ ]+]] = insertvalue [8 x half] [[ret1]], half [[v2]], 2
; CHECK:  [[ret3:%[^ ]+]] = insertvalue [8 x half] [[ret2]], half [[v3]], 3
; CHECK:  [[ret4:%[^ ]+]] = insertvalue [8 x half] [[ret3]], half [[v4]], 4
; CHECK:  [[ret5:%[^ ]+]] = insertvalue [8 x half] [[ret4]], half [[v5]], 5
; CHECK:  [[ret6:%[^ ]+]] = insertvalue [8 x half] [[ret5]], half [[v6]], 6
; CHECK:  insertvalue [8 x half] [[ret6]], half [[v7]], 7

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x float>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x half], ptr addrspace(1) %0, i32 %i
  %1 = load [8 x half], ptr addrspace(1) %arrayidx, align 8
  store [8 x half] %1, ptr addrspace(1) %b, align 8
  ret void
}

