; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[shr]]
; CHECK:  [[ld0:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]], align 4
; CHECK:  [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]], align 4

; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <2 x half> [[ld0]] to <4 x i8>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <2 x half> [[ld1]] to <4 x i8>

; CHECK:  [[val0:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 0
; CHECK:  [[val1:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 1
; CHECK:  [[val2:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 2
; CHECK:  [[val3:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 3
; CHECK:  [[val4:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 0
; CHECK:  [[val5:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 1
; CHECK:  [[val6:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 2
; CHECK:  [[val7:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 3

; CHECK:  [[ret0:%[^ ]+]] = insertvalue [8 x i8] undef, i8 [[val0]], 0
; CHECK:  [[ret1:%[^ ]+]] = insertvalue [8 x i8] [[ret0]], i8 [[val1]], 1
; CHECK:  [[ret2:%[^ ]+]] = insertvalue [8 x i8] [[ret1]], i8 [[val2]], 2
; CHECK:  [[ret3:%[^ ]+]] = insertvalue [8 x i8] [[ret2]], i8 [[val3]], 3
; CHECK:  [[ret4:%[^ ]+]] = insertvalue [8 x i8] [[ret3]], i8 [[val4]], 4
; CHECK:  [[ret5:%[^ ]+]] = insertvalue [8 x i8] [[ret4]], i8 [[val5]], 5
; CHECK:  [[ret6:%[^ ]+]] = insertvalue [8 x i8] [[ret5]], i8 [[val6]], 6
; CHECK:  insertvalue [8 x i8] [[ret6]], i8 [[val7]], 7

define spir_kernel void @foo(<2 x half> addrspace(1)* %a, [8 x i8] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <2 x half> addrspace(1)* %a to [8 x i8] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i8], [8 x i8] addrspace(1)* %0, i32 %i
  %1 = load [8 x i8], [8 x i8] addrspace(1)* %arrayidx, align 8
  store [8 x i8] %1, [8 x i8] addrspace(1)* %b, align 8
  ret void
}

