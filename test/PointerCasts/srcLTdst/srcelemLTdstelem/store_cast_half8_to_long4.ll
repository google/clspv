; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 3
; CHECK:  [[ext0:%[^ ]+]] = extractelement <4 x i64> %0, i64 0
; CHECK:  [[ext1:%[^ ]+]] = extractelement <4 x i64> %0, i64 1
; CHECK:  [[ext2:%[^ ]+]] = extractelement <4 x i64> %0, i64 2
; CHECK:  [[ext3:%[^ ]+]] = extractelement <4 x i64> %0, i64 3

; CHECK:  [[bitcast0:%[^ ]+]] = bitcast i64 [[ext0]] to <4 x half>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast i64 [[ext1]] to <4 x half>
; CHECK:  [[bitcast2:%[^ ]+]] = bitcast i64 [[ext2]] to <4 x half>
; CHECK:  [[bitcast3:%[^ ]+]] = bitcast i64 [[ext3]] to <4 x half>

; CHECK:  [[ext0:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 0
; CHECK:  [[ext1:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 1
; CHECK:  [[ext2:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 2
; CHECK:  [[ext3:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 3
; CHECK:  [[ext4:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 0
; CHECK:  [[ext5:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 1
; CHECK:  [[ext6:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 2
; CHECK:  [[ext7:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 3
; CHECK:  [[ext8:%[^ ]+]] = extractelement <4 x half> [[bitcast2]], i64 0
; CHECK:  [[ext9:%[^ ]+]] = extractelement <4 x half> [[bitcast2]], i64 1
; CHECK:  [[ext10:%[^ ]+]] = extractelement <4 x half> [[bitcast2]], i64 2
; CHECK:  [[ext11:%[^ ]+]] = extractelement <4 x half> [[bitcast2]], i64 3
; CHECK:  [[ext12:%[^ ]+]] = extractelement <4 x half> [[bitcast3]], i64 0
; CHECK:  [[ext13:%[^ ]+]] = extractelement <4 x half> [[bitcast3]], i64 1
; CHECK:  [[ext14:%[^ ]+]] = extractelement <4 x half> [[bitcast3]], i64 2
; CHECK:  [[ext15:%[^ ]+]] = extractelement <4 x half> [[bitcast3]], i64 3

; CHECK:  [[ins0:%[^ ]+]] = insertvalue [8 x half] undef, half [[ext0]], 0
; CHECK:  [[ins1:%[^ ]+]] = insertvalue [8 x half] [[ins0]], half [[ext1]], 1
; CHECK:  [[ins2:%[^ ]+]] = insertvalue [8 x half] [[ins1]], half [[ext2]], 2
; CHECK:  [[ins3:%[^ ]+]] = insertvalue [8 x half] [[ins2]], half [[ext3]], 3
; CHECK:  [[ins4:%[^ ]+]] = insertvalue [8 x half] [[ins3]], half [[ext4]], 4
; CHECK:  [[ins5:%[^ ]+]] = insertvalue [8 x half] [[ins4]], half [[ext5]], 5
; CHECK:  [[ins6:%[^ ]+]] = insertvalue [8 x half] [[ins5]], half [[ext6]], 6
; CHECK:  [[ins7:%[^ ]+]] = insertvalue [8 x half] [[ins6]], half [[ext7]], 7

; CHECK:  [[ins8:%[^ ]+]] = insertvalue [8 x half] undef, half [[ext8]], 0
; CHECK:  [[ins9:%[^ ]+]] = insertvalue [8 x half] [[ins8]], half [[ext9]], 1
; CHECK:  [[ins10:%[^ ]+]] = insertvalue [8 x half] [[ins9]], half [[ext10]], 2
; CHECK:  [[ins11:%[^ ]+]] = insertvalue [8 x half] [[ins10]], half [[ext11]], 3
; CHECK:  [[ins12:%[^ ]+]] = insertvalue [8 x half] [[ins11]], half [[ext12]], 4
; CHECK:  [[ins13:%[^ ]+]] = insertvalue [8 x half] [[ins12]], half [[ext13]], 5
; CHECK:  [[ins14:%[^ ]+]] = insertvalue [8 x half] [[ins13]], half [[ext14]], 6
; CHECK:  [[ins15:%[^ ]+]] = insertvalue [8 x half] [[ins14]], half [[ext15]], 7

; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %1, i32 [[shr]]
; CHECK:  store [8 x half] [[ins7]], ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %1, i32 [[add]]
; CHECK:  store [8 x half] [[ins15]], ptr addrspace(1) [[gep]]

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load <4 x i64>, ptr addrspace(1) %b, align 8
  %1 = getelementptr [8 x half], ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <4 x i64>, ptr addrspace(1) %1, i32 %i
  store <4 x i64> %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

