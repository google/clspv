; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 3
; CHECK: [[shuffle0:%[^ ]+]] = shufflevector <4 x i32> %0, <4 x i32> poison, <2 x i32> <i32 0, i32 1>
; CHECK: [[shuffle1:%[^ ]+]] = shufflevector <4 x i32> %0, <4 x i32> poison, <2 x i32> <i32 2, i32 3>
; CHECK: [[bitcast0:%[^ ]+]] = bitcast <2 x i32> [[shuffle0]] to <4 x i16>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <2 x i32> [[shuffle1]] to <4 x i16>
; CHECK: [[elem0:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 0
; CHECK: [[elem1:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 1
; CHECK: [[elem2:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 2
; CHECK: [[elem3:%[^ ]+]] = extractelement <4 x i16> [[bitcast0]], i64 3
; CHECK: [[elem4:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 0
; CHECK: [[elem5:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 1
; CHECK: [[elem6:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 2
; CHECK: [[elem7:%[^ ]+]] = extractelement <4 x i16> [[bitcast1]], i64 3
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[shl]]
; CHECK: store i16 [[elem0]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add:%[^ ]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add]]
; CHECK: store i16 [[elem1]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add2]]
; CHECK: store i16 [[elem2]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add3]]
; CHECK: store i16 [[elem3]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add4]]
; CHECK: store i16 [[elem4]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add5]]
; CHECK: store i16 [[elem5]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add6]]
; CHECK: store i16 [[elem6]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add7]]
; CHECK: store i16 [[elem7]], i16 addrspace(1)* [[gep]], align 2

define spir_kernel void @foo(i16 addrspace(1)* %a, <4 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <4 x i32>, <4 x i32> addrspace(1)* %b, align 16
  %1 = bitcast i16 addrspace(1)* %a to <4 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <4 x i32>, <4 x i32> addrspace(1)* %1, i32 %i
  store <4 x i32> %0, <4 x i32> addrspace(1)* %arrayidx, align 16
  ret void
}
