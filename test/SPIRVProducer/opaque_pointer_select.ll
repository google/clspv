; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK: [[float3:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 3
; CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float3]]
; CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[ptr]]
; CHECK: OpStore [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 16 %a, ptr addrspace(1) nocapture writeonly align 16 %b, { i32 } %podargs) !clspv.pod_args_impl !10 !kernel_arg_map !11 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <3 x float>] } zeroinitializer)
  %1 = getelementptr { [0 x <3 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x <3 x float>] } zeroinitializer)
  %3 = getelementptr { [0 x <3 x float>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %5 = getelementptr { { i32 } }, ptr addrspace(9) %4, i32 0, i32 0
  %6 = load { i32 }, ptr addrspace(9) %5, align 4
  %n = extractvalue { i32 } %6, 0
  %cmp.i = icmp sgt i32 %n, 10
  %a.b = select i1 %cmp.i, ptr addrspace(1) %1, ptr addrspace(1) %3
  store <3 x float> <float 1.000000e+00, float 2.000000e+00, float 3.000000e+00>, ptr addrspace(1) %a.b, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <3 x float>] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <3 x float>] })
declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!10 = !{i32 2}
!11 = !{!12, !13, !14}
!12 = !{!"a", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!13 = !{!"b", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!14 = !{!"n", i32 2, i32 2, i32 0, i32 4, !"pod_pushconstant"}

