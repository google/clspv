; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[shr]]
; CHECK: [[ld0:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add4]]
; CHECK: [[ld4:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add5]]
; CHECK: [[ld5:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add6]]
; CHECK: [[ld6:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, <2 x i8> addrspace(1)* %a, i32 [[add7]]
; CHECK: [[ld7:%[^ ]+]] = load <2 x i8>, <2 x i8> addrspace(1)* [[gep]]

; CHECK: [[in0:%[^ ]+]] = shufflevector <2 x i8> [[ld0]], <2 x i8> [[ld1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in1:%[^ ]+]] = shufflevector <2 x i8> [[ld2]], <2 x i8> [[ld3]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in2:%[^ ]+]] = shufflevector <2 x i8> [[ld4]], <2 x i8> [[ld5]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in3:%[^ ]+]] = shufflevector <2 x i8> [[ld6]], <2 x i8> [[ld7]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x i8> [[in0]] to <2 x i16>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x i8> [[in1]] to <2 x i16>
; CHECK: [[bitcast2:%[^ ]+]] = bitcast <4 x i8> [[in2]] to <2 x i16>
; CHECK: [[bitcast3:%[^ ]+]] = bitcast <4 x i8> [[in3]] to <2 x i16>

; CHECK: [[in0:%[^ ]+]] = shufflevector <2 x i16> [[bitcast0]], <2 x i16> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in1:%[^ ]+]] = shufflevector <2 x i16> [[bitcast2]], <2 x i16> [[bitcast3]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x i16> [[in0]] to <2 x i32>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x i16> [[in1]] to <2 x i32>

; CHECK: [[in:%[^ ]+]] = shufflevector <2 x i32> [[bitcast0]], <2 x i32> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: shufflevector <4 x i32> [[in]], <4 x i32> poison, <3 x i32> <i32 0, i32 1, i32 2>

define spir_kernel void @foo(<2 x i8> addrspace(1)* %a, <3 x i32> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <2 x i8> addrspace(1)* %a to <3 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <3 x i32>, <3 x i32> addrspace(1)* %0, i32 %i
  %1 = load <3 x i32>, <3 x i32> addrspace(1)* %arrayidx, align 8
  store <3 x i32> %1, <3 x i32> addrspace(1)* %b, align 8
  ret void
}

