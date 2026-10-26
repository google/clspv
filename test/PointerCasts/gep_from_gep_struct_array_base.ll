; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[pts:%[a-zA-Z0-9_.]+]] = alloca [4 x %struct.P]
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr [4 x %struct.P], ptr [[pts]], i32 0, i32 1, i32 0
; CHECK: store i16 1, ptr [[gep1]]
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr [4 x %struct.P], ptr [[pts]], i32 0, i32 2, i32 1
; CHECK: store i32 2, ptr [[gep2]]
; CHECK: getelementptr [4 x %struct.P], ptr [[pts]], i32 0, i32 %i, i32 0

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.P = type { i16, i32 }

define spir_kernel void @k(ptr addrspace(1) %out, i32 %i) {
entry:
  %pts = alloca [4 x %struct.P], align 4
  %a = getelementptr i8, ptr %pts, i32 8
  %a.x = getelementptr %struct.P, ptr %a, i32 0, i32 0
  store i16 1, ptr %a.x, align 4
  %b = getelementptr i8, ptr %pts, i32 16
  %b.y = getelementptr %struct.P, ptr %b, i32 0, i32 1
  store i32 2, ptr %b.y, align 4
  %c = getelementptr [4 x %struct.P], ptr %pts, i32 0, i32 %i
  %l = load i16, ptr %c, align 4
  store i16 %l, ptr addrspace(1) %out, align 2
  ret void
}
