; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; We expect to have nothing changed, especially, we should not fall in a
; infinite loop in SimplifyPointerBitcastPass::runOnUnneededIndices

; CHECK:  %0 = getelementptr half, ptr addrspace(1) %in, i32 0
; CHECK:  %1 = load <4 x i32>, ptr addrspace(1) %0, align 16


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in) {
entry:
  %0 = getelementptr half, ptr addrspace(1) %in, i32 0
  %1 = load <4 x i32>, ptr addrspace(1) %0, align 16
  ret void
}
