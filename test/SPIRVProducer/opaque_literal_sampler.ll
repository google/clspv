; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[sampler]]
; CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[ptr]] UniformConstant

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%ocl_image2d_ro.float.sampled = type opaque
%opencl.sampler_t = type opaque

define spir_kernel void @test(ptr addrspace(1) %t, ptr addrspace(1) nocapture writeonly align 16 %out, { <2 x float> } %podargs) !clspv.pod_args_impl !4 !kernel_arg_map !10 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 1, i32 0, i32 6, i32 0, i32 0, i32 0, %ocl_image2d_ro.float.sampled zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 1, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %2 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0
  %3 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { <2 x float> } } zeroinitializer)
  %4 = getelementptr { { <2 x float> } }, ptr addrspace(9) %3, i32 0, i32 0
  %5 = load { <2 x float> }, ptr addrspace(9) %4, align 8
  %coords = extractvalue { <2 x float> } %5, 0
  %6 = call ptr addrspace(2) @_Z25clspv.sampler_var_literal(i32 0, i32 0, i32 21, %opencl.sampler_t zeroinitializer)
  %call.i = tail call spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampled11ocl_samplerDv2_f(ptr addrspace(1) %0, ptr addrspace(2) %6, <2 x float> %coords)
  store <4 x float> %call.i, ptr addrspace(1) %2, align 16
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef28ocl_image2d_ro.float.sampled11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>)
declare ptr addrspace(2) @_Z25clspv.sampler_var_literal(i32, i32, i32, %opencl.sampler_t)
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, %ocl_image2d_ro.float.sampled)
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })
declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { <2 x float> } })

!clspv.descriptor.index = !{!4}

!4 = !{i32 2}
!10 = !{!11, !12, !13}
!11 = !{!"t", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!12 = !{!"out", i32 2, i32 1, i32 0, i32 0, !"buffer"}
!13 = !{!"coords", i32 1, i32 2, i32 0, i32 8, !"pod_pushconstant"}
