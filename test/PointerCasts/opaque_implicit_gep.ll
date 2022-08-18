; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer

define spir_kernel void @test() {
entry:
  ; CHECK: %[[gep:[a-zA-Z0-9+]]] = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  ; CHECK: load i32, ptr addrspace(5) %[[gep]]
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  ret void
}
