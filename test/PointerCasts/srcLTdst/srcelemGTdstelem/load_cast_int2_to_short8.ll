; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %0, i32 [[shr]]
; CHECK:  [[ld0:%[^ ]+]] = load <2 x i32>, ptr addrspace(1) [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %0, i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load <2 x i32>, ptr addrspace(1) [[gep]]

; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <2 x i32> [[ld0]] to <4 x i16>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <2 x i32> [[ld1]] to <4 x i16>

; CHECK:  [[val0:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 0
; CHECK:  [[val1:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 1
; CHECK:  [[val2:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 2
; CHECK:  [[val3:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 3
; CHECK:  [[val4:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 0
; CHECK:  [[val5:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 1
; CHECK:  [[val6:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 2
; CHECK:  [[val7:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 3

; CHECK:  [[ret0:%[^ ]+]] = insertvalue [8 x i16] poison, i16 [[val0]], 0
; CHECK:  [[ret1:%[^ ]+]] = insertvalue [8 x i16] [[ret0]], i16 [[val1]], 1
; CHECK:  [[ret2:%[^ ]+]] = insertvalue [8 x i16] [[ret1]], i16 [[val2]], 2
; CHECK:  [[ret3:%[^ ]+]] = insertvalue [8 x i16] [[ret2]], i16 [[val3]], 3
; CHECK:  [[ret4:%[^ ]+]] = insertvalue [8 x i16] [[ret3]], i16 [[val4]], 4
; CHECK:  [[ret5:%[^ ]+]] = insertvalue [8 x i16] [[ret4]], i16 [[val5]], 5
; CHECK:  [[ret6:%[^ ]+]] = insertvalue [8 x i16] [[ret5]], i16 [[val6]], 6
; CHECK:  insertvalue [8 x i16] [[ret6]], i16 [[val7]], 7

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x i32>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x i16], ptr addrspace(1) %0, i32 %i
  %1 = load [8 x i16], ptr addrspace(1) %arrayidx, align 8
  store [8 x i16] %1, ptr addrspace(1) %b, align 8
  ret void
}

