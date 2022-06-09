; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[^ ]+]] = getelementptr [8 x half], [8 x half] addrspace(1)* %b, i32 %i
; CHECK: [[ld:%[^ ]+]] = load [8 x half], [8 x half] addrspace(1)* [[gep]]
; CHECK: [[ex0:%[^ ]+]] = extractvalue [8 x half] [[ld]], 0
; CHECK: [[ex1:%[^ ]+]] = extractvalue [8 x half] [[ld]], 1
; CHECK: [[ex2:%[^ ]+]] = extractvalue [8 x half] [[ld]], 2
; CHECK: [[ex3:%[^ ]+]] = extractvalue [8 x half] [[ld]], 3
; CHECK: [[ex4:%[^ ]+]] = extractvalue [8 x half] [[ld]], 4
; CHECK: [[ex5:%[^ ]+]] = extractvalue [8 x half] [[ld]], 5
; CHECK: [[ex6:%[^ ]+]] = extractvalue [8 x half] [[ld]], 6
; CHECK: [[ex7:%[^ ]+]] = extractvalue [8 x half] [[ld]], 7

; CHECK: [[in0:%[^ ]+]] = insertelement <4 x half> undef, half [[ex0]], i32 0
; CHECK: [[in1:%[^ ]+]] = insertelement <4 x half> [[in0]], half [[ex1]], i32 1
; CHECK: [[in2:%[^ ]+]] = insertelement <4 x half> [[in1]], half [[ex2]], i32 2
; CHECK: [[in3:%[^ ]+]] = insertelement <4 x half> [[in2]], half [[ex3]], i32 3
; CHECK: [[in4:%[^ ]+]] = insertelement <4 x half> undef, half [[ex4]], i32 0
; CHECK: [[in5:%[^ ]+]] = insertelement <4 x half> [[in4]], half [[ex5]], i32 1
; CHECK: [[in6:%[^ ]+]] = insertelement <4 x half> [[in5]], half [[ex6]], i32 2
; CHECK: [[in7:%[^ ]+]] = insertelement <4 x half> [[in6]], half [[ex7]], i32 3

; CHECK: [[bitcast0:%[^ ]+]] = bitcast <4 x half> [[in3]] to <2 x i32>
; CHECK: [[bitcast1:%[^ ]+]] = bitcast <4 x half> [[in7]] to <2 x i32>

; CHECK: [[shuffle:%[^ ]+]] = shufflevector <2 x i32> [[bitcast0]], <2 x i32> [[bitcast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: shufflevector <4 x i32> [[shuffle]], <4 x i32> poison, <3 x i32> <i32 0, i32 1, i32 2>

define spir_kernel void @foo(<3 x i32> addrspace(1)* %a, [8 x half] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast [8 x half] addrspace(1)* %b to <3 x i32> addrspace(1)*
  %arrayidx = getelementptr inbounds <3 x i32>, <3 x i32> addrspace(1)* %0, i32 %i
  %1 = load <3 x i32>, <3 x i32> addrspace(1)* %arrayidx, align 8
  store <3 x i32> %1, <3 x i32> addrspace(1)* %a, align 8
  ret void
}


