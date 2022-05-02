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

; CHECK: [[insert0:%[^ ]+]] = insertelement <4 x half> undef, half [[extract0]], i32 0
; CHECK: [[insert1:%[^ ]+]] = insertelement <4 x half> [[insert0]], half [[extract1]], i32 1
; CHECK: [[insert2:%[^ ]+]] = insertelement <4 x half> [[insert1]], half [[extract2]], i32 2
; CHECK: [[insertA:%[^ ]+]] = insertelement <4 x half> [[insert2]], half [[extract3]], i32 3
; CHECK: [[insert0:%[^ ]+]] = insertelement <4 x half> undef, half [[extract4]], i32 0
; CHECK: [[insert1:%[^ ]+]] = insertelement <4 x half> [[insert0]], half [[extract5]], i32 1
; CHECK: [[insert2:%[^ ]+]] = insertelement <4 x half> [[insert1]], half [[extract6]], i32 2
; CHECK: [[insertB:%[^ ]+]] = insertelement <4 x half> [[insert2]], half [[extract7]], i32 3

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x half> [[insertA]] to <2 x i32>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x half> [[insertB]] to <2 x i32>
; CHECK: shufflevector <2 x i32> [[bitcast0]], <2 x i32> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

define spir_kernel void @foo([8 x half] addrspace(1)* %a, <4 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast [8 x half] addrspace(1)* %a to <4 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <4 x i32>, <4 x i32> addrspace(1)* %0, i32 %i
  %1 = load <4 x i32>, <4 x i32> addrspace(1)* %arrayidx, align 8
  store <4 x i32> %1, <4 x i32> addrspace(1)* %b, align 8
  ret void
}

