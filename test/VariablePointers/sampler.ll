; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK-NOT: OpCapability VariablePointers
; CHECK-NOT: OpExtension "SPV_KHR_variable_pointers"

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <2 x float>)

define spir_kernel void @foo(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %im1, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %im2) !clspv.pod_args_impl !8 {
entry:
  %0 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 1, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) undef)
  %1 = call target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.1(i32 1, i32 1, i32 6, i32 1, i32 1, i32 0, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) undef)
  %2 = call target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 18, target("spirv.Sampler") zeroinitializer)
  br label %for.body

for.body:                                         ; preds = %for.body, %entry
  %l.03 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %3 = tail call <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %2, <2 x float> zeroinitializer)
  %inc = add nuw nsw i32 %l.03, 1
  %cmp = icmp uge i32 %l.03, 29
  br i1 %cmp, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  %4 = tail call <4 x float> @_Z11read_imagef30ocl_image2d_ro_t.float.sampled11ocl_samplerDv2_f(target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) %1, target("spirv.Sampler") %2, <2 x float> zeroinitializer)
  ret void
}

declare target("spirv.Sampler") @_Z25clspv.sampler_var_literal(i32, i32, i32, target("spirv.Sampler"))

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

declare target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 0, 0, 1, 0, 0, 0))

!8 = !{i32 2}

