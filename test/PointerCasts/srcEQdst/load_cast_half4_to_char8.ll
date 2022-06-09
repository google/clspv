; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %a, i32 %i
; CHECK: [[ld:%[^ ]+]] = load [8 x half], [8 x half] addrspace(1)* [[gep]]

; CHECK: [[extract0:%[^ ]+]] = extractvalue [8 x half] [[ld]], 0
; CHECK: [[extract1:%[^ ]+]] = extractvalue [8 x half] [[ld]], 1
; CHECK: [[extract2:%[^ ]+]] = extractvalue [8 x half] [[ld]], 2
; CHECK: [[extract3:%[^ ]+]] = extractvalue [8 x half] [[ld]], 3
; CHECK: [[extract4:%[^ ]+]] = extractvalue [8 x half] [[ld]], 4
; CHECK: [[extract5:%[^ ]+]] = extractvalue [8 x half] [[ld]], 5
; CHECK: [[extract6:%[^ ]+]] = extractvalue [8 x half] [[ld]], 6
; CHECK: [[extract7:%[^ ]+]] = extractvalue [8 x half] [[ld]], 7

; CHECK: [[bitcast0:%[^ ]+]] = bitcast half [[extract0]] to i16
; CHECK: [[bitcast1:%[^ ]+]] = bitcast half [[extract1]] to i16
; CHECK: [[bitcast2:%[^ ]+]] = bitcast half [[extract2]] to i16
; CHECK: [[bitcast3:%[^ ]+]] = bitcast half [[extract3]] to i16
; CHECK: [[bitcast4:%[^ ]+]] = bitcast half [[extract4]] to i16
; CHECK: [[bitcast5:%[^ ]+]] = bitcast half [[extract5]] to i16
; CHECK: [[bitcast6:%[^ ]+]] = bitcast half [[extract6]] to i16
; CHECK: [[bitcast7:%[^ ]+]] = bitcast half [[extract7]] to i16

; CHECK: [[insert0:%[^ ]+]] = insertvalue [8 x i16] undef, i16 [[bitcast0]], 0
; CHECK: [[insert1:%[^ ]+]] = insertvalue [8 x i16] [[insert0]], i16 [[bitcast1]], 1
; CHECK: [[insert2:%[^ ]+]] = insertvalue [8 x i16] [[insert1]], i16 [[bitcast2]], 2
; CHECK: [[insert3:%[^ ]+]] = insertvalue [8 x i16] [[insert2]], i16 [[bitcast3]], 3
; CHECK: [[insert4:%[^ ]+]] = insertvalue [8 x i16] [[insert3]], i16 [[bitcast4]], 4
; CHECK: [[insert5:%[^ ]+]] = insertvalue [8 x i16] [[insert4]], i16 [[bitcast5]], 5
; CHECK: [[insert6:%[^ ]+]] = insertvalue [8 x i16] [[insert5]], i16 [[bitcast6]], 6
; CHECK: [[insert7:%[^ ]+]] = insertvalue [8 x i16] [[insert6]], i16 [[bitcast7]], 7

define spir_kernel void @foo([8 x half] addrspace(1)* %a, [8 x i16] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast [8 x half] addrspace(1)* %a to [8 x i16] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i16], [8 x i16] addrspace(1)* %0, i32 %i
  %1 = load [8 x i16], [8 x i16] addrspace(1)* %arrayidx, align 8
  store [8 x i16] %1, [8 x i16] addrspace(1)* %b, align 8
  ret void
}

