; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %0, i32 [[shr]]
; CHECK:  [[ld0:%[^ ]+]] = load [8 x half], ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %0, i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load [8 x half], ptr addrspace(1) [[gep]]

; CHECK:  [[ext0:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 0
; CHECK:  [[ext1:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 1
; CHECK:  [[ext2:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 2
; CHECK:  [[ext3:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 3
; CHECK:  [[ext4:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 4
; CHECK:  [[ext5:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 5
; CHECK:  [[ext6:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 6
; CHECK:  [[ext7:%[^ ]+]] = extractvalue [8 x half] [[ld0]], 7

; CHECK:  [[ext8:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 0
; CHECK:  [[ext9:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 1
; CHECK:  [[ext10:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 2
; CHECK:  [[ext11:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 3
; CHECK:  [[ext12:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 4
; CHECK:  [[ext13:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 5
; CHECK:  [[ext14:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 6
; CHECK:  [[ext15:%[^ ]+]] = extractvalue [8 x half] [[ld1]], 7

; CHECK:  [[ins0:%[^ ]+]] = insertelement <4 x half> poison, half [[ext0]], i32 0
; CHECK:  [[ins1:%[^ ]+]] = insertelement <4 x half> [[ins0]], half [[ext1]], i32 1
; CHECK:  [[ins2:%[^ ]+]] = insertelement <4 x half> [[ins1]], half [[ext2]], i32 2
; CHECK:  [[ins3:%[^ ]+]] = insertelement <4 x half> [[ins2]], half [[ext3]], i32 3

; CHECK:  [[ins4:%[^ ]+]] = insertelement <4 x half> poison, half [[ext4]], i32 0
; CHECK:  [[ins5:%[^ ]+]] = insertelement <4 x half> [[ins4]], half [[ext5]], i32 1
; CHECK:  [[ins6:%[^ ]+]] = insertelement <4 x half> [[ins5]], half [[ext6]], i32 2
; CHECK:  [[ins7:%[^ ]+]] = insertelement <4 x half> [[ins6]], half [[ext7]], i32 3

; CHECK:  [[ins8:%[^ ]+]] = insertelement <4 x half> poison, half [[ext8]], i32 0
; CHECK:  [[ins9:%[^ ]+]] = insertelement <4 x half> [[ins8]], half [[ext9]], i32 1
; CHECK:  [[ins10:%[^ ]+]] = insertelement <4 x half> [[ins9]], half [[ext10]], i32 2
; CHECK:  [[ins11:%[^ ]+]] = insertelement <4 x half> [[ins10]], half [[ext11]], i32 3

; CHECK:  [[ins12:%[^ ]+]] = insertelement <4 x half> poison, half [[ext12]], i32 0
; CHECK:  [[ins13:%[^ ]+]] = insertelement <4 x half> [[ins12]], half [[ext13]], i32 1
; CHECK:  [[ins14:%[^ ]+]] = insertelement <4 x half> [[ins13]], half [[ext14]], i32 2
; CHECK:  [[ins15:%[^ ]+]] = insertelement <4 x half> [[ins14]], half [[ext15]], i32 3

; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <4 x half> [[ins3]] to <2 x i32>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <4 x half> [[ins7]] to <2 x i32>
; CHECK:  [[bitcast2:%[^ ]+]] = bitcast <4 x half> [[ins11]] to <2 x i32>
; CHECK:  [[bitcast3:%[^ ]+]] = bitcast <4 x half> [[ins15]] to <2 x i32>

; CHECK:  [[shuffle0:%[^ ]+]] = shufflevector <2 x i32> [[bitcast0]], <2 x i32> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[shuffle1:%[^ ]+]] = shufflevector <2 x i32> [[bitcast2]], <2 x i32> [[bitcast3]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <4 x i32> [[shuffle0]] to <2 x i64>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <4 x i32> [[shuffle1]] to <2 x i64>
; CHECK:  shufflevector <2 x i64> [[bitcast0]], <2 x i64> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr [8 x half], ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <4 x i64>, ptr addrspace(1) %0, i32 %i
  %1 = load <4 x i64>, ptr addrspace(1) %arrayidx, align 8
  store <4 x i64> %1, ptr addrspace(1) %b, align 8
  ret void
}

