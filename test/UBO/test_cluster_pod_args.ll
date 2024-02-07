; RUN: clspv-opt -constant-args-ubo -pod-ubo %s -o %t -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck %s < %t.map
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; TODO(#1303): invalid LLVM IR is produced in SPIRVProducer
; XFAIL: *

; Just checking that the argument names are recorded correctly when clustering pod args.

;      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
; MAP-NEXT: kernel,foo,arg,n,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.data_type = type { i32, [12 x i8] }

@c_var = local_unnamed_addr addrspace(2) constant [2 x %struct.data_type] [%struct.data_type { i32 0, [12 x i8] undef }, %struct.data_type { i32 1, [12 x i8] undef }], align 16
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c_arg, { i32 } %podargs) !clspv.pod_args_impl !8 !kernel_arg_map !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.data_type] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x %struct.data_type] } zeroinitializer)
  %2 = call ptr addrspace(6) @_Z14clspv.resource.2(i32 0, i32 2, i32 4, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %3 = getelementptr { { i32 } }, ptr addrspace(6) %2, i32 0, i32 0
  %4 = load { i32 }, ptr addrspace(6) %3, align 4
  %n = extractvalue { i32 } %4, 0
  %5 = getelementptr { [4096 x %struct.data_type] }, ptr addrspace(2) %1, i32 0, i32 0, i32 %n, i32 0
  %6 = load i32, ptr addrspace(2) %5, align 16
  %7 = getelementptr [2 x %struct.data_type], ptr addrspace(2) @c_var, i32 0, i32 %n, i32 0
  %8 = load i32, ptr addrspace(2) %7, align 16
  %add.i = add nsw i32 %8, %6
  %9 = getelementptr { [0 x %struct.data_type] }, ptr addrspace(1) %0, i32 0, i32 0, i32 %n, i32 0
  store i32 %add.i, ptr addrspace(1) %9, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.data_type] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x %struct.data_type] })

declare ptr addrspace(6) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!8 = !{i32 1}
!14 = !{!15, !16, !17}
!15 = !{!"data", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!16 = !{!"c_arg", i32 1, i32 1, i32 0, i32 0, !"buffer_ubo"}
!17 = !{!"n", i32 2, i32 2, i32 0, i32 4, !"pod_ubo"}

