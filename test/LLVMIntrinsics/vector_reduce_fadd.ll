; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: [[extract:%[^ ]+]] = extractelement <4 x float> %vector, i32 0
; CHECK: [[fadd0:%[^ ]+]] = fadd float %start_value, [[extract]]
; CHECK: [[extract:%[^ ]+]] = extractelement <4 x float> %vector, i32 1
; CHECK: [[fadd1:%[^ ]+]] = fadd float [[fadd0]], [[extract]]
; CHECK: [[extract:%[^ ]+]] = extractelement <4 x float> %vector, i32 2
; CHECK: [[fadd2:%[^ ]+]] = fadd float [[fadd1]], [[extract]]
; CHECK: [[extract:%[^ ]+]] = extractelement <4 x float> %vector, i32 3
; CHECK: [[fadd3:%[^ ]+]] = fadd float [[fadd2]], [[extract]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(float %start_value, <4 x float> %vector) {
entry:
  %res = call float @llvm.vector.reduce.fadd.v4f32(float %start_value, <4 x float> %vector)
  ret void
}

declare float @llvm.vector.reduce.fadd.v4f32(float, <4 x float>)
