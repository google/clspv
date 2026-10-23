; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[pts:%[a-zA-Z0-9_.]+]] = alloca [2 x %struct.P]
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 0, i32 1
; CHECK: store i16 1, ptr [[gep2]]
; CHECK: [[gep4:%[a-zA-Z0-9_.]+]] = getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 1, i32 0
; CHECK: store i16 2, ptr [[gep4]]
; CHECK: [[gep6:%[a-zA-Z0-9_.]+]] = getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 1, i32 1
; CHECK: store i16 3, ptr [[gep6]]
; CHECK: getelementptr [2 x %struct.P], ptr [[pts]], i32 0, i32 %i, i32 0

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.P = type { i16, i16 }

define spir_kernel void @k(ptr addrspace(1) %out, i32 %i) {
entry:
  %pts = alloca [2 x %struct.P], align 2
  %a = getelementptr i8, ptr %pts, i32 2
  store i16 1, ptr %a, align 2
  %b = getelementptr i8, ptr %pts, i32 4
  store i16 2, ptr %b, align 2
  %c = getelementptr i8, ptr %pts, i32 6
  store i16 3, ptr %c, align 2
  %d = getelementptr [2 x %struct.P], ptr %pts, i32 0, i32 %i
  %l = load i16, ptr %d, align 2
  store i16 %l, ptr addrspace(1) %out, align 2
  ret void
}
