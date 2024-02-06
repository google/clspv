; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK-NOT: OpCapability VariablePointers
; CHECK-NOT: OpExtension "SPV_KHR_variable_pointers"
; CHECK: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage
; CHECK: OpFunctionParameter [[image]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func void @_Z12write_imagef22ocl_image2d_wo_t.floatDv2_iDv4_f(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0), <2 x i32>, <4 x float>)

define spir_func void @bar(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) %image) {
entry:
  tail call spir_func void @_Z12write_imagef22ocl_image2d_wo_t.floatDv2_iDv4_f(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) %image, <2 x i32> zeroinitializer, <4 x float> zeroinitializer)
  ret void
}

define spir_kernel void @foo(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) %image) !clspv.pod_args_impl !15 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 7, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) undef)
  tail call spir_func void @bar(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) %0)
  ret void
}

declare target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 1, 0))

!15 = !{i32 2}

