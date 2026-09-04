; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

declare void @llvm.memset.p1.i32(ptr addrspace(1), i8, i32, i1)

define spir_kernel void @test() {
entry:
  %0 = alloca float, align 4
  %dst = addrspacecast ptr %0 to ptr addrspace(1)
  call void @llvm.memset.p1.i32(ptr addrspace(1) %dst, i8 0, i32 4, i1 false)
  ret void
}

; CHECK-LABEL: @test
; CHECK: %[[gep:[a-zA-Z0-9_]+]] = getelementptr float, ptr addrspace(1) %dst, i32 0
; CHECK: store float 0.000000e+00, ptr addrspace(1) %[[gep]]
