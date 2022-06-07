; RUN: clspv -x ir %s -o %t.spv -opaque-pointers=0
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: spirv-dis %t.spv -o - | FileCheck %s

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test() {
entry:
  unreachable
}

; CHECK: OpFunction
; CHECK-NEXT: OpLabel
; CHECK-NEXT: OpUnreachable
; CHECK-NEXT: OpFunctionEnd
