; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[extract0:%[^ ]+]] = extractvalue [8 x half] %0, 0
; CHECK: [[extract1:%[^ ]+]] = extractvalue [8 x half] %0, 1
; CHECK: [[extract2:%[^ ]+]] = extractvalue [8 x half] %0, 2
; CHECK: [[extract3:%[^ ]+]] = extractvalue [8 x half] %0, 3
; CHECK: [[extract4:%[^ ]+]] = extractvalue [8 x half] %0, 4
; CHECK: [[extract5:%[^ ]+]] = extractvalue [8 x half] %0, 5
; CHECK: [[extract6:%[^ ]+]] = extractvalue [8 x half] %0, 6
; CHECK: [[extract7:%[^ ]+]] = extractvalue [8 x half] %0, 7

; CHECK: [[bitcast0:%[^ ]+]] = bitcast half [[extract0]] to <2 x i8>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast half [[extract1]] to <2 x i8>
; CHECK: [[bitcast2:%[^ ]+]] = bitcast half [[extract2]] to <2 x i8>
; CHECK: [[bitcast3:%[^ ]+]] = bitcast half [[extract3]] to <2 x i8>
; CHECK: [[bitcast4:%[^ ]+]] = bitcast half [[extract4]] to <2 x i8>
; CHECK: [[bitcast5:%[^ ]+]] = bitcast half [[extract5]] to <2 x i8>
; CHECK: [[bitcast6:%[^ ]+]] = bitcast half [[extract6]] to <2 x i8>
; CHECK: [[bitcast7:%[^ ]+]] = bitcast half [[extract7]] to <2 x i8>

; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[shr]]
; CHECK: store <2 x i8> [[bitcast0]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add]]
; CHECK: store <2 x i8> [[bitcast1]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add2]]
; CHECK: store <2 x i8> [[bitcast2]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add3]]
; CHECK: store <2 x i8> [[bitcast3]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add4]]
; CHECK: store <2 x i8> [[bitcast4]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add5]]
; CHECK: store <2 x i8> [[bitcast5]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add6]]
; CHECK: store <2 x i8> [[bitcast6]], <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add7]]
; CHECK: store <2 x i8> [[bitcast7]], <2 x i8> addrspace(1)* [[gep]]

define spir_kernel void @foo(<2 x i8> addrspace(1)* %a, [8 x half] addrspace(1)* %b, i32 %i) {
entry:
  %0 = load [8 x half], [8 x half] addrspace(1)* %b, align 8
  %1 = bitcast <2 x i8> addrspace(1)* %a to [8 x half] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x half], [8 x half] addrspace(1)* %1, i32 %i
  store [8 x half] %0, [8 x half] addrspace(1)* %arrayidx, align 8
  ret void
}

