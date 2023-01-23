; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[ld:%[^ ]+]] = load <4 x i32>, ptr addrspace(1) %b

; CHECK: [[extract0:%[^ ]+]] = shufflevector <4 x i32> [[ld]], <4 x i32> poison, <2 x i32> <i32 0, i32 1>
; CHECK: [[extract1:%[^ ]+]] = shufflevector <4 x i32> [[ld]], <4 x i32> poison, <2 x i32> <i32 2, i32 3>

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <2 x i32> [[extract0]] to <4 x half>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <2 x i32> [[extract1]] to <4 x half>

; CHECK: [[extract0:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 0
; CHECK: [[extract1:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 1
; CHECK: [[extract2:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 2
; CHECK: [[extract3:%[^ ]+]] = extractelement <4 x half> [[bitcast0]], i64 3
; CHECK: [[extract4:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 0
; CHECK: [[extract5:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 1
; CHECK: [[extract6:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 2
; CHECK: [[extract7:%[^ ]+]] = extractelement <4 x half> [[bitcast1]], i64 3

; CHECK: [[insert0:%[^ ]+]] = insertvalue [8 x half] undef, half [[extract0]], 0
; CHECK: [[insert1:%[^ ]+]] = insertvalue [8 x half] [[insert0]], half [[extract1]], 1
; CHECK: [[insert2:%[^ ]+]] = insertvalue [8 x half] [[insert1]], half [[extract2]], 2
; CHECK: [[insert3:%[^ ]+]] = insertvalue [8 x half] [[insert2]], half [[extract3]], 3
; CHECK: [[insert4:%[^ ]+]] = insertvalue [8 x half] [[insert3]], half [[extract4]], 4
; CHECK: [[insert5:%[^ ]+]] = insertvalue [8 x half] [[insert4]], half [[extract5]], 5
; CHECK: [[insert6:%[^ ]+]] = insertvalue [8 x half] [[insert5]], half [[extract6]], 6
; CHECK: [[insert7:%[^ ]+]] = insertvalue [8 x half] [[insert6]], half [[extract7]], 7

; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], ptr addrspace(1) %1, i32 %i
; CHECK: store [8 x half] [[insert7]], ptr addrspace(1) [[gep]]

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load <4 x i32>, ptr addrspace(1) %b, align 8
  %1 = getelementptr [8 x half], ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <4 x i32>, ptr addrspace(1) %1, i32 %i
  store <4 x i32> %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

