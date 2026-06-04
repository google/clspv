; RUN: clspv -x=ir %s -o %t.spv
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-unknown-vulkan"

define spir_kernel void @floor_float(ptr addrspace(1) noalias %out, float %x) {
entry:
  %call = call spir_func float @llvm.floor.f32(float %x)
  store float %call, ptr addrspace(1) %out, align 32
  ret void
}

declare spir_func float @llvm.floor.f32(float)

; CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
; CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
; CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Floor
