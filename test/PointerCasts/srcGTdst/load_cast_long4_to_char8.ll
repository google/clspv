; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 %i, 2
; CHECK:  [[and:%[^ ]+]] = and i32 %i, 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %b, i32 [[lshr]], i32 [[and]]
; CHECK:  [[load:%[^ ]+]] = load i64, i64 addrspace(1)* [[gep]]
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i64 [[load]] to <4 x i16>
; CHECK:  [[shuffle0:%[^ ]+]] = shufflevector <4 x i16> [[bitcast]], <4 x i16> poison, <2 x i32> <i32 0, i32 1>
; CHECK:  [[shuffle1:%[^ ]+]] = shufflevector <4 x i16> [[bitcast]], <4 x i16> poison, <2 x i32> <i32 2, i32 3>
; CHECK:  [[bitcast0:%[^ ]+]] = bitcast <2 x i16> [[shuffle0]] to <4 x i8>
; CHECK:  [[bitcast1:%[^ ]+]] = bitcast <2 x i16> [[shuffle1]] to <4 x i8>
; CHECK:  [[ex0:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 0
; CHECK:  [[ex1:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 1
; CHECK:  [[ex2:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 2
; CHECK:  [[ex3:%[^ ]+]] = extractelement <4 x i8> [[bitcast0]], i64 3
; CHECK:  [[ex4:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 0
; CHECK:  [[ex5:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 1
; CHECK:  [[ex6:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 2
; CHECK:  [[ex7:%[^ ]+]] = extractelement <4 x i8> [[bitcast1]], i64 3
; CHECK:  [[in0:%[^ ]+]] = insertvalue [8 x i8] undef, i8 [[ex0]], 0
; CHECK:  [[in1:%[^ ]+]] = insertvalue [8 x i8] [[in0]], i8 [[ex1]], 1
; CHECK:  [[in2:%[^ ]+]] = insertvalue [8 x i8] [[in1]], i8 [[ex2]], 2
; CHECK:  [[in3:%[^ ]+]] = insertvalue [8 x i8] [[in2]], i8 [[ex3]], 3
; CHECK:  [[in4:%[^ ]+]] = insertvalue [8 x i8] [[in3]], i8 [[ex4]], 4
; CHECK:  [[in5:%[^ ]+]] = insertvalue [8 x i8] [[in4]], i8 [[ex5]], 5
; CHECK:  [[in6:%[^ ]+]] = insertvalue [8 x i8] [[in5]], i8 [[ex6]], 6
; CHECK:  [[in7:%[^ ]+]] = insertvalue [8 x i8] [[in6]], i8 [[ex7]], 7

define spir_kernel void @foo([8 x i8] addrspace(1)* %a, <4 x i64> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x i64> addrspace(1)* %b to [8 x i8] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i8], [8 x i8] addrspace(1)* %0, i32 %i
  %1 = load [8 x i8], [8 x i8] addrspace(1)* %arrayidx, align 8
  store [8 x i8] %1, [8 x i8] addrspace(1)* %a, align 8
  ret void
}


