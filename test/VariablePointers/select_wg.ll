; RUN: clspv-opt %s -o %t -producer-out-file %t.spv --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK: OpCapability VariablePointers
; CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK: [[ptr:%[^ ]+]] = OpTypePointer Workgroup [[uint]]
; CHECK: [[select:%[^ ]+]] = OpSelect [[ptr]]
; CHECK: [[load:%[^ ]+]] = OpLoad [[uint]] [[select]]
; CHECK: OpStore {{.*}} [[load]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: readwrite, inaccessiblemem: none)
define spir_kernel void @foo(ptr addrspace(3) readonly align 4 captures(none) %in1, ptr addrspace(3) readonly align 4 captures(none) %in2, ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %out, { i32 } %podargs) !clspv.pod_args_impl !23 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x i32] zeroinitializer)
  %1 = getelementptr [0 x i32], ptr addrspace(3) %0, i32 0, i32 0
  %2 = call ptr addrspace(3) @_Z11clspv.local.4(i32 4, [0 x i32] zeroinitializer)
  %3 = getelementptr [0 x i32], ptr addrspace(3) %2, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 2, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %5 = getelementptr { [0 x i32] }, ptr addrspace(1) %4, i32 0, i32 0, i32 0
  %6 = call ptr addrspace(9) @_Z14clspv.resource.1(i32 -1, i32 1, i32 5, i32 3, i32 1, i32 0, { { i32 } } zeroinitializer)
  %7 = getelementptr { { i32 } }, ptr addrspace(9) %6, i32 0, i32 0
  %8 = load { i32 }, ptr addrspace(9) %7, align 4
  %a = extractvalue { i32 } %8, 0
  %cmp.i.i = icmp eq i32 %a, 0
  %in1.in2 = select i1 %cmp.i.i, ptr addrspace(3) %1, ptr addrspace(3) %3
  %9 = load i32, ptr addrspace(3) %in1.in2, align 4
  store i32 %9, ptr addrspace(1) %5, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { { i32 } })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x i32])

declare ptr addrspace(3) @_Z11clspv.local.4(i32, [0 x i32])

!23 = !{i32 2}

; Extracted from the following source with the following options 'clspv %s -o %t.spv --print-before=spirv-producer &> %t.ll':
;
;kernel void foo(local int *in1, local int* in2, global int* out, int a) {
;  local int* z = (a == 0) ? in1 : in2;
;  *out = *z;
;}
