; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 3
; CHECK: [[shuffle:%[^ ]+]] = shufflevector <4 x i32> %0, <4 x i32> undef, <2 x i32> <i32 0, i32 1>
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x i32> [[shuffle]] to <4 x i16>
; CHECK: [[elem0:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 0
; CHECK: [[elem1:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 1
; CHECK: [[elem2:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 2
; CHECK: [[elem3:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 3
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

; CHECK: [[shuffle:%[^ ]+]] = shufflevector <4 x i32> %0, <4 x i32> undef, <2 x i32> <i32 2, i32 3>
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x i32> [[shuffle]] to <4 x i16>
; CHECK: [[elem0:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 0
; CHECK: [[elem1:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 1
; CHECK: [[elem2:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 2
; CHECK: [[elem3:%[^ ]+]] = extractelement <4 x i16> [[bitcast]], i32 3
; CHECK: [[add:%[^ ]+]] = add i32 [[shl]], 4
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add]]
; CHECK: store i16 [[elem0]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add1:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add1]]
; CHECK: store i16 [[elem1]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add2:%[^ ]+]] = add i32 [[add1]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add2]]
; CHECK: store i16 [[elem2]], i16 addrspace(1)* [[gep]], align 2
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* %a, i32 [[add3]]
; CHECK: store i16 [[elem3]], i16 addrspace(1)* [[gep]], align 2

define spir_kernel void @foo(i16 addrspace(1)* %a, <4 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <4 x i32>, <4 x i32> addrspace(1)* %b, align 16
  %1 = bitcast i16 addrspace(1)* %a to <4 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <4 x i32>, <4 x i32> addrspace(1)* %1, i32 %i
  store <4 x i32> %0, <4 x i32> addrspace(1)* %arrayidx, align 16
  ret void
}
