; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[ld:%[^ ]+]] = load [8 x i8], [8 x i8] addrspace(1)* %b

; CHECK: [[extract0:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 0
; CHECK: [[extract1:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 1
; CHECK: [[extract2:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 2
; CHECK: [[extract3:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 3
; CHECK: [[extract4:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 4
; CHECK: [[extract5:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 5
; CHECK: [[extract6:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 6
; CHECK: [[extract7:%[^ ]+]] = extractvalue [8 x i8] [[ld]], 7

; CHECK: [[insert0:%[^ ]+]] = insertelement <4 x i8> undef, i8 [[extract0]], i32 0
; CHECK: [[insert1:%[^ ]+]] = insertelement <4 x i8> [[insert0]], i8 [[extract1]], i32 1
; CHECK: [[insert2:%[^ ]+]] = insertelement <4 x i8> [[insert1]], i8 [[extract2]], i32 2
; CHECK: [[insert3:%[^ ]+]] = insertelement <4 x i8> [[insert2]], i8 [[extract3]], i32 3

; CHECK: [[insert4:%[^ ]+]] = insertelement <4 x i8> undef, i8 [[extract4]], i32 0
; CHECK: [[insert5:%[^ ]+]] = insertelement <4 x i8> [[insert4]], i8 [[extract5]], i32 1
; CHECK: [[insert6:%[^ ]+]] = insertelement <4 x i8> [[insert5]], i8 [[extract6]], i32 2
; CHECK: [[insert7:%[^ ]+]] = insertelement <4 x i8> [[insert6]], i8 [[extract7]], i32 3

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x i8> [[insert3]] to <2 x half>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x i8> [[insert7]] to <2 x half>
; CHECK: [[shuffle:%[^ ]+]] = shufflevector <2 x half> [[bitcast0]], <2 x half> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

; CHECK: [[gep:%[^ ]+]] = getelementptr <4 x half>, <4 x half> addrspace(1)* %a, i32 %i
; CHECK: store <4 x half> [[shuffle]], <4 x half> addrspace(1)* [[gep]]

define spir_kernel void @foo(<4 x half> addrspace(1)* %a, [8 x i8] addrspace(1)* %b, i32 %i) {
entry:
  %0 = load [8 x i8], [8 x i8] addrspace(1)* %b, align 8
  %1 = bitcast <4 x half> addrspace(1)* %a to [8 x i8] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i8], [8 x i8] addrspace(1)* %1, i32 %i
  store [8 x i8] %0, [8 x i8] addrspace(1)* %arrayidx, align 8
  ret void
}

