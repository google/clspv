; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK:  [[ext0:%[^ ]+]] = extractvalue [8 x half] %0, 0
; CHECK:  [[ext1:%[^ ]+]] = extractvalue [8 x half] %0, 1
; CHECK:  [[ext2:%[^ ]+]] = extractvalue [8 x half] %0, 2
; CHECK:  [[ext3:%[^ ]+]] = extractvalue [8 x half] %0, 3
; CHECK:  [[ext4:%[^ ]+]] = extractvalue [8 x half] %0, 4
; CHECK:  [[ext5:%[^ ]+]] = extractvalue [8 x half] %0, 5
; CHECK:  [[ext6:%[^ ]+]] = extractvalue [8 x half] %0, 6
; CHECK:  [[ext7:%[^ ]+]] = extractvalue [8 x half] %0, 7
; CHECK:  [[ins0:%[^ ]+]] = insertelement <4 x half> undef, half [[ext0]], i32 0
; CHECK:  [[ins1:%[^ ]+]] = insertelement <4 x half> [[ins0]], half [[ext1]], i32 1
; CHECK:  [[ins2:%[^ ]+]] = insertelement <4 x half> [[ins1]], half [[ext2]], i32 2
; CHECK:  [[ins3:%[^ ]+]] = insertelement <4 x half> [[ins2]], half [[ext3]], i32 3
; CHECK:  [[ins4:%[^ ]+]] = insertelement <4 x half> undef, half [[ext4]], i32 0
; CHECK:  [[ins5:%[^ ]+]] = insertelement <4 x half> [[ins4]], half [[ext5]], i32 1
; CHECK:  [[ins6:%[^ ]+]] = insertelement <4 x half> [[ins5]], half [[ext6]], i32 2
; CHECK:  [[ins7:%[^ ]+]] = insertelement <4 x half> [[ins6]], half [[ext7]], i32 3
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <4 x half> [[ins3]] to <2 x float>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <4 x half> [[ins7]] to <2 x float>
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x float>, <2 x float> addrspace(1)* %a, i32 [[shr]]
; CHECK:  store <2 x float> [[bitcast0]], <2 x float> addrspace(1)* [[gep]], align 8
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x float>, <2 x float> addrspace(1)* %a, i32 [[add]]
; CHECK:  store <2 x float> [[bitcast1]], <2 x float> addrspace(1)* [[gep]], align 8

define spir_kernel void @foo(<2 x float> addrspace(1)* %a, [8 x half] addrspace(1)* %b, i32 %i) {
entry:
  %0 = load [8 x half], [8 x half] addrspace(1)* %b, align 8
  %1 = bitcast <2 x float> addrspace(1)* %a to [8 x half] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x half], [8 x half] addrspace(1)* %1, i32 %i
  store [8 x half] %0, [8 x half] addrspace(1)* %arrayidx, align 8
  ret void
}

