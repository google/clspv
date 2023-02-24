; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[ld:%[^ ]+]] = load [8 x i16], ptr addrspace(1) %b

; CHECK: [[extract0:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 0
; CHECK: [[extract1:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 1
; CHECK: [[extract2:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 2
; CHECK: [[extract3:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 3
; CHECK: [[extract4:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 4
; CHECK: [[extract5:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 5
; CHECK: [[extract6:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 6
; CHECK: [[extract7:%[^ ]+]] = extractvalue [8 x i16] [[ld]], 7

; CHECK: [[bitcast0:%[^ ]+]] = bitcast i16 [[extract0]] to half
; CHECK: [[bitcast1:%[^ ]+]] = bitcast i16 [[extract1]] to half
; CHECK: [[bitcast2:%[^ ]+]] = bitcast i16 [[extract2]] to half
; CHECK: [[bitcast3:%[^ ]+]] = bitcast i16 [[extract3]] to half
; CHECK: [[bitcast4:%[^ ]+]] = bitcast i16 [[extract4]] to half
; CHECK: [[bitcast5:%[^ ]+]] = bitcast i16 [[extract5]] to half
; CHECK: [[bitcast6:%[^ ]+]] = bitcast i16 [[extract6]] to half
; CHECK: [[bitcast7:%[^ ]+]] = bitcast i16 [[extract7]] to half

; CHECK: [[insert0:%[^ ]+]] = insertvalue [8 x half] poison, half [[bitcast0]], 0
; CHECK: [[insert1:%[^ ]+]] = insertvalue [8 x half] [[insert0]], half [[bitcast1]], 1
; CHECK: [[insert2:%[^ ]+]] = insertvalue [8 x half] [[insert1]], half [[bitcast2]], 2
; CHECK: [[insert3:%[^ ]+]] = insertvalue [8 x half] [[insert2]], half [[bitcast3]], 3
; CHECK: [[insert4:%[^ ]+]] = insertvalue [8 x half] [[insert3]], half [[bitcast4]], 4
; CHECK: [[insert5:%[^ ]+]] = insertvalue [8 x half] [[insert4]], half [[bitcast5]], 5
; CHECK: [[insert6:%[^ ]+]] = insertvalue [8 x half] [[insert5]], half [[bitcast6]], 6
; CHECK: [[insert7:%[^ ]+]] = insertvalue [8 x half] [[insert6]], half [[bitcast7]], 7

; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %1, i32 %i
; CHECK: store [8 x half] [[insert7]], ptr addrspace(1) [[gep]]

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load [8 x i16], ptr addrspace(1) %b, align 8
  %1 = getelementptr [8 x half], ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x i16], ptr addrspace(1) %1, i32 %i
  store [8 x i16] %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

