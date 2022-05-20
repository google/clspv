; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i32:32-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 3
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl]], 7
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i32], [8 x i32] addrspace(1)* %b, i32 [[shr]], i32 [[and]]
; CHECK:  [[ld0:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i32], [8 x i32] addrspace(1)* %b, i32 [[shr]], i32 [[add]]
; CHECK:  [[ld1:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i32], [8 x i32] addrspace(1)* %b, i32 [[shr]], i32 [[add2]]
; CHECK:  [[ld2:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr [8 x i32], [8 x i32] addrspace(1)* %b, i32 [[shr]], i32 [[add3]]
; CHECK:  [[ld3:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]]
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast i32 [[ld0]] to <2 x i16>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast i32 [[ld1]] to <2 x i16>
; CHECK:  [[bitcast2:%[^ ]+]] = bitcast i32 [[ld2]] to <2 x i16>
; CHECK:  [[bitcast3:%[^ ]+]] = bitcast i32 [[ld3]] to <2 x i16>
; CHECK:  [[ex0:%[^ ]+]] = extractelement <2 x i16> [[bitcast0]], i64 0
; CHECK:  [[ex1:%[^ ]+]] = extractelement <2 x i16> [[bitcast0]], i64 1
; CHECK:  [[ex2:%[^ ]+]] = extractelement <2 x i16> [[bitcast1]], i64 0
; CHECK:  [[ex3:%[^ ]+]] = extractelement <2 x i16> [[bitcast1]], i64 1
; CHECK:  [[ex4:%[^ ]+]] = extractelement <2 x i16> [[bitcast2]], i64 0
; CHECK:  [[ex5:%[^ ]+]] = extractelement <2 x i16> [[bitcast2]], i64 1
; CHECK:  [[ex6:%[^ ]+]] = extractelement <2 x i16> [[bitcast3]], i64 0
; CHECK:  [[ex7:%[^ ]+]] = extractelement <2 x i16> [[bitcast3]], i64 1
; CHECK:  [[in0:%[^ ]+]] = insertvalue [8 x i16] undef, i16 [[ex0]], 0
; CHECK:  [[in1:%[^ ]+]] = insertvalue [8 x i16] [[in0]], i16 [[ex1]], 1
; CHECK:  [[in2:%[^ ]+]] = insertvalue [8 x i16] [[in1]], i16 [[ex2]], 2
; CHECK:  [[in3:%[^ ]+]] = insertvalue [8 x i16] [[in2]], i16 [[ex3]], 3
; CHECK:  [[in4:%[^ ]+]] = insertvalue [8 x i16] [[in3]], i16 [[ex4]], 4
; CHECK:  [[in5:%[^ ]+]] = insertvalue [8 x i16] [[in4]], i16 [[ex5]], 5
; CHECK:  [[in6:%[^ ]+]] = insertvalue [8 x i16] [[in5]], i16 [[ex6]], 6
; CHECK:  insertvalue [8 x i16] [[in6]], i16 [[ex7]], 7

define spir_kernel void @foo([8 x i16] addrspace(1)* %a, [8 x i32] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast [8 x i32] addrspace(1)* %b to [8 x i16] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i16], [8 x i16] addrspace(1)* %0, i32 %i
  %1 = load [8 x i16], [8 x i16] addrspace(1)* %arrayidx, align 8
  store [8 x i16] %1, [8 x i16] addrspace(1)* %a, align 8
  ret void
}


