; RUN: clspv-opt %s -o %t.ll --untyped-pointers -spv-version=1.4 --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: OpCapability UntypedPointers
; CHECK-DAG: OpCapability WorkgroupMemoryExplicitLayoutKHR
; CHECK-DAG: OpExtension "SPV_KHR_untyped_pointers"
; CHECK-DAG: OpExtension "SPV_KHR_workgroup_memory_explicit_layout"

; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[test_wg2_block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[uint]]
; CHECK-DAG: [[rta:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[uint]]
; CHECK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[size:%[a-zA-Z0-9_]+]]
; CHECK-DAG: [[ssbo_block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta]]
; CHECK-DAG: [[wg_block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[array]]

; CHECK-DAG: OpDecorate [[test_wg2_block]] Block
; CHECK-DAG: OpMemberDecorate [[test_wg2_block]] 0 Offset 0
; CHECK-DAG: OpDecorate [[ssbo_block]] Block
; CHECK-DAG: OpMemberDecorate [[ssbo_block]] 0 Offset 0
; CHECK-DAG: OpDecorate [[wg_block]] Block
; CHECK-DAG: OpMemberDecorate [[wg_block]] 0 Offset 0
; CHECK-DAG: OpDecorate [[array]] ArrayStride 4
; CHECK-DAG: OpDecorate [[rta]] ArrayStride 4
; CHECK-DAG: OpDecorate [[size]] SpecId 3

; CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
; CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
; CHECK-DAG: [[uint_6:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 6
; CHECK-DAG: [[ptr_wg:%[a-zA-Z0-9_]+]] = OpTypeUntypedPointerKHR Workgroup
; CHECK-DAG: [[ptr_ssbo:%[a-zA-Z0-9_]+]] = OpTypeUntypedPointerKHR StorageBuffer

; CHECK-DAG: [[test_wg2:%[a-zA-Z0-9_]+]] = OpUntypedVariableKHR [[ptr_wg]] Workgroup [[test_wg2_block]]
; CHECK-DAG: [[wg_var:%[a-zA-Z0-9_]+]] = OpUntypedVariableKHR [[ptr_wg]] Workgroup [[wg_block]]

; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpUntypedAccessChainKHR [[ptr_wg]] [[ssbo_block]] [[wg_var]] [[uint_0]] [[uint_0]]
; CHECK: [[ssbo_gep:%[a-zA-Z0-9_]+]] = OpUntypedAccessChainKHR [[ptr_ssbo]] [[ssbo_block]] %{{.*}} [[uint_0]] [[uint_6]]
; CHECK: [[ptr_gep:%[a-zA-Z0-9_]+]] = OpUntypedAccessChainKHR [[ptr_wg]] [[rta]] [[gep]] [[uint_4]]
; CHECK: OpStore [[ptr_gep]]
; CHECK: OpControlBarrier
; CHECK: [[ssbo_ptr_gep:%[a-zA-Z0-9_]+]] = OpUntypedAccessChainKHR [[ptr_ssbo]] [[rta]] [[ssbo_gep]] [[uint_6]]
; CHECK: OpStore [[ssbo_ptr_gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@test.wg2.0 = internal unnamed_addr addrspace(3) global i32 undef, align 4
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @test(ptr addrspace(1) readonly align 4 captures(none) %in, ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %out, ptr addrspace(3) noalias writeonly align 4 captures(none) initializes((0, 4)) %wg1, { i32, i32 } %podargs) local_unnamed_addr !kernel_arg_addr_space !13 !kernel_arg_access_qual !14 !kernel_arg_type !15 !kernel_arg_base_type !15 !kernel_arg_type_qual !16 !kernel_arg_name !17 !clspv.pod_args_impl !18 !kernel_arg_map !19 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(3) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %5 = getelementptr { [0 x i32] }, ptr addrspace(1) %4, i32 0, i32 0, i32 6
  %6 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 3, i32 2, i32 0, { { i32, i32 } } zeroinitializer)
  %7 = getelementptr { { i32, i32 } }, ptr addrspace(9) %6, i32 0, i32 0
  %8 = load { i32, i32 }, ptr addrspace(9) %7, align 4
  %x = extractvalue { i32, i32 } %8, 0
  %y = extractvalue { i32, i32 } %8, 1
  tail call void @llvm.experimental.noalias.scope.decl(metadata !25)
  %9 = load i32, ptr addrspace(1) %3, align 4, !noalias !25
  %add.i.i = add nsw i32 %9, %y
  %ptr_access_wg = getelementptr i32, ptr addrspace(3) %1, i32 4
  store i32 %add.i.i, ptr addrspace(3) %ptr_access_wg, align 4, !alias.scope !25
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264)
  %add1.i.i = add nsw i32 %add.i.i, %x
  store i32 %add1.i.i, ptr addrspace(3) @test.wg2.0, align 4, !noalias !28
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264)
  %10 = load i32, ptr addrspace(3) @test.wg2.0, align 4, !noalias !28
  %ptr_access_ssbo = getelementptr i32, ptr addrspace(1) %5, i32 6
  store i32 %10, ptr addrspace(1) %ptr_access_ssbo, align 4, !noalias !25
  ret void
}

declare !kernel_arg_name !31 void @llvm.experimental.noalias.scope.decl(metadata)

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) local_unnamed_addr

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32, i32 } })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, { [0 x i32] })


!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4}
!llvm.ident = !{!5, !6}
!_Z28clspv.entry_point_attributes = !{!7, !8}
!clspv.descriptor.index = !{!9}
!clspv.next_spec_constant_id = !{!10}
!clspv.spec_constant_list = !{!11}
!_Z20clspv.local_spec_ids = !{!12}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{i32 3, i32 0}
!5 = !{!"clang version 22.0.0git (https://github.com/llvm/llvm-project d5ce81dc8143eed18a7342093b991a63b025e2d9)"}
!6 = !{!"clang version 22.0.0git (https://github.com/llvm/llvm-project af86add989a6156ccff99dd5e0ebd9ab30538d0f)"}
!7 = !{!"test", !"kernel"}
!8 = !{!"__clang_ocl_kern_imp_test", !"kernel"}
!9 = !{i32 1}
!10 = distinct !{i32 4}
!11 = !{i32 3, i32 3}
!12 = !{ptr @test, i32 2, i32 3}
!13 = !{i32 1, i32 1, i32 0, i32 0, i32 3}
!14 = !{!"none", !"none", !"none", !"none", !"none"}
!15 = !{!"int*", !"int*", !"int", !"int", !"int*"}
!16 = !{!"", !"", !"", !"", !"restrict"}
!17 = !{!"in", !"out", !"x", !"y", !"wg1"}
!18 = !{i32 2}
!19 = !{!20, !21, !22, !23, !24}
!20 = !{!"in", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!21 = !{!"out", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!22 = !{!"wg1", i32 4, i32 2, i32 0, i32 0, !"local"}
!23 = !{!"x", i32 2, i32 3, i32 0, i32 4, !"pod_pushconstant"}
!24 = !{!"y", i32 3, i32 3, i32 4, i32 4, !"pod_pushconstant"}
!25 = !{!26}
!26 = distinct !{!26, !27, !"test.inner: %wg1"}
!27 = distinct !{!27, !"test.inner"}
!28 = !{!29, !26}
!29 = distinct !{!29, !30, !"__clang_ocl_kern_imp_test: %wg1"}
!30 = distinct !{!30, !"__clang_ocl_kern_imp_test"}
!31 = !{!""}

