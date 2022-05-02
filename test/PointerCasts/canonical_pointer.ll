; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(float addrspace(1)* nocapture readonly %input, <4 x float> addrspace(1)* nocapture %output)  {
entry:
  %in = alloca [4 x [4 x float]], align 16
  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %in, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], [4 x float]* [[base]]
  ; CHECK: extractvalue [4 x float] [[load4]], 0
  ; CHECK: extractvalue [4 x float] [[load4]], 1
  ; CHECK: extractvalue [4 x float] [[load4]], 2
  ; CHECK: extractvalue [4 x float] [[load4]], 3
  %bc0 = bitcast [4 x [4 x float]]* %in to <4 x float>*
  %ld0 = load <4 x float>, <4 x float>* %bc0

  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %gep1, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], [4 x float]* [[base]]
  ; CHECK: extractvalue [4 x float] [[load4]], 0
  ; CHECK: extractvalue [4 x float] [[load4]], 1
  ; CHECK: extractvalue [4 x float] [[load4]], 2
  ; CHECK: extractvalue [4 x float] [[load4]], 3
  %gep1 = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %in
  %bc1 = bitcast [4 x [4 x float]]* %gep1 to <4 x float>*
  %ld1 = load <4 x float>, <4 x float>* %bc1

  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %gep2, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], [4 x float]* [[base]]
  ; CHECK: extractvalue [4 x float] [[load4]], 0
  ; CHECK: extractvalue [4 x float] [[load4]], 1
  ; CHECK: extractvalue [4 x float] [[load4]], 2
  ; CHECK: extractvalue [4 x float] [[load4]], 3
  %gep2 = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %in, i32 0
  %bc2 = bitcast [4 x [4 x float]]* %gep2 to <4 x float>*
  %ld2 = load <4 x float>, <4 x float>* %bc2

  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x float], [4 x float]* %gep3, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], [4 x float]* [[base]]
  ; CHECK: extractvalue [4 x float] [[load4]], 0
  ; CHECK: extractvalue [4 x float] [[load4]], 1
  ; CHECK: extractvalue [4 x float] [[load4]], 2
  ; CHECK: extractvalue [4 x float] [[load4]], 3

  %gep3 = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %in, i32 0, i32 0
  %bc3 = bitcast [4 x float]* %gep3 to <4 x float>*
  %ld3 = load <4 x float>, <4 x float>* %bc3

  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float* %gep4, i32 0
  ; CHECK: load float, float* [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float* %gep4, i32 1
  ; CHECK: load float, float* [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float* %gep4, i32 2
  ; CHECK: load float, float* [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, float* %gep4, i32 3
  ; CHECK: load float, float* [[gep]]
  %gep4 = getelementptr [4 x [4 x float]], [4 x [4 x float]]* %in, i32 0, i32 0, i32 0
  %bc4 = bitcast float* %gep4 to <4 x float>*
  %ld4 = load <4 x float>, <4 x float>* %bc4
  ret void
}

