; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.Matrix = type { [4 x [4 x float]] }
%struct.Outer = type { i32, %struct.Matrix }

; CHECK-LABEL: define spir_kernel void @foo(
; CHECK: %[[GEP:[a-zA-Z0-9_]+]] = getelementptr %struct.Outer, ptr addrspace(1) %m, i32 0, i32 1, i32 0, i32 0
; CHECK-NEXT: %[[LD:[a-zA-Z0-9_]+]] = load <4 x float>, ptr addrspace(1) %[[GEP]], align 16
; CHECK-NEXT: store <4 x float> %[[LD]], ptr addrspace(1) %out, align 16

define spir_kernel void @foo(ptr addrspace(1) %m, ptr addrspace(1) %out) {
entry:
  %gep = getelementptr %struct.Outer, ptr addrspace(1) %m, i32 0, i32 1, i32 0, i32 0, i32 0
  %ld = load <4 x float>, ptr addrspace(1) %gep, align 16
  store <4 x float> %ld, ptr addrspace(1) %out, align 16
  ret void
}
