; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpImageWrite %{{.*}} %{{.*}} %{{.*}} SignExtend

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func void @_Z12write_imagei23opencl.image2d_wo_t.intDv2_iDv4_j(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0), <2 x i32>, <4 x i32>)

define spir_kernel void @foo(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) addrspace(1)* %i)!clspv.pod_args_impl !8 {
entry:
  %0 = call target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 7, i32 0, i32 0, i32 0, target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) undef)
  tail call spir_func void @_Z12write_imagei23opencl.image2d_wo_t.intDv2_iDv4_j(target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) %0, <2 x i32> zeroinitializer, <4 x i32> zeroinitializer)
  ret void
}

declare target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", i32, 1, 0, 0, 0, 2, 0, 1, 0))

!8 = !{i32 2}

