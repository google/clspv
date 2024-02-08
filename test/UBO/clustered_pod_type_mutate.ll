; RUN: clspv-opt -constant-args-ubo %s -o %t.ll -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

; MAP:      kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,a,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod_ubo,argSize,4
; MAP-NEXT: kernel,foo,arg,s,argOrdinal,2,descriptorSet,0,binding,1,offset,16,argKind,pod_ubo,argSize,16

; CHECK: OpMemberDecorate
; CHECK: OpMemberDecorate [[S:%[a-zA-Z0-9_]+]] 0 Offset 0
; CHECK: OpMemberDecorate [[S]] 1 Offset 4
; CHECK: OpMemberDecorate [[cluster:%[a-zA-Z0-9_]+]] 0 Offset 0
; CHECK: OpMemberDecorate [[cluster]] 1 Offset 4
; CHECK: OpMemberDecorate [[cluster]] 2 Offset 8
; CHECK: OpMemberDecorate [[cluster]] 3 Offset 12
; CHECK: OpMemberDecorate [[cluster]] 4 Offset 16
; CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
; CHECK: [[S]] = OpTypeStruct [[int]] [[char]]
; CHECK: [[cluster]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]] [[S]]
; CHECK: [[pod_var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[pod_var]]
; CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[cluster]] [[gep]]
; CHECK: [[a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[ld]] 0
; CHECK: [[s:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[S]] [[ld]] 4
; CHECK: [[s_a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[s]] 0
; CHECK: OpIAdd [[int]] [[s_a]] [[a]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { i32, [12 x i8] }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture align 16 %out, { i32, i32, i32, i32, %struct.S } %podargs) !clspv.pod_args_impl !8 !kernel_arg_map !15 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(6) @_Z14clspv.resource.1(i32 0, i32 1, i32 4, i32 1, i32 1, i32 0, { { i32, i32, i32, i32, %struct.S } } zeroinitializer)
  %3 = getelementptr { { i32, i32, i32, i32, %struct.S } }, ptr addrspace(6) %2, i32 0, i32 0
  %4 = load { i32, i32, i32, i32, %struct.S }, ptr addrspace(6) %3, align 4
  %a = extractvalue { i32, i32, i32, i32, %struct.S } %4, 0
  %s = extractvalue { i32, i32, i32, i32, %struct.S } %4, 4
  %s.elt = extractvalue %struct.S %s, 0
  %add.i = add nsw i32 %s.elt, %a
  %5 = load <4 x i32>, ptr addrspace(1) %1, align 16
  %6 = insertelement <4 x i32> %5, i32 %add.i, i64 0
  store <4 x i32> %6, ptr addrspace(1) %1, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare ptr addrspace(6) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { { i32, i32, i32, i32, %struct.S } })

!8 = !{i32 1}
!15 = !{!16, !17, !18}
!16 = !{!"out", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!17 = !{!"a", i32 1, i32 1, i32 0, i32 4, !"pod_ubo"}
!18 = !{!"s", i32 2, i32 1, i32 16, i32 16, !"pod_ubo"}

