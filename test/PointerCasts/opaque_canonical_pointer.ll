; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) nocapture readonly %input, ptr addrspace(1) nocapture %output)  {
entry:
  %in = alloca [4 x [4 x float]], align 16
  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], ptr %in, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], ptr [[base]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 1
  ; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 2
  ; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 3
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> poison, float [[ex0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[ex1]], i32 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[ex2]], i32 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[ex3]], i32 3
  %ld0 = load <4 x float>, <4 x float>* %in

  %gep1 = getelementptr [4 x [4 x float]], ptr %in
  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], ptr %gep1, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], ptr [[base]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 1
  ; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 2
  ; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 3
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> poison, float [[ex0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[ex1]], i32 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[ex2]], i32 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[ex3]], i32 3
  %ld1 = load <4 x float>, ptr %gep1

  %gep2 = getelementptr [4 x [4 x float]], ptr %in, i32 0
  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x [4 x float]], ptr %gep2, i32 0, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], ptr [[base]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 1
  ; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 2
  ; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 3
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> poison, float [[ex0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[ex1]], i32 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[ex2]], i32 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[ex3]], i32 3
  %ld2 = load <4 x float>, ptr %gep2

  %gep3 = getelementptr [4 x [4 x float]], ptr %in, i32 0, i32 0
  ; CHECK: [[base:%[a-zA-Z0-9_.]+]] = getelementptr [4 x float], ptr %gep3, i32 0
  ; CHECK: [[load4:%[a-zA-Z0-9_.]+]] = load [4 x float], ptr [[base]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 1
  ; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 2
  ; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x float] [[load4]], 3
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> poison, float [[ex0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[ex1]], i32 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[ex2]], i32 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[ex3]], i32 3
  %ld3 = load <4 x float>, ptr %gep3

  %gep4 = getelementptr [4 x [4 x float]], ptr %in, i32 0, i32 0, i32 0
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr %gep4, i32 0
  ; CHECK: load float, ptr [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr %gep4, i32 1
  ; CHECK: load float, ptr [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr %gep4, i32 2
  ; CHECK: load float, ptr [[gep]]
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr %gep4, i32 3
  ; CHECK: load float, ptr [[gep]]
  %ld4 = load <4 x float>, ptr %gep4

  ret void
}
