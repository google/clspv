; RUN: clspv-opt %s -o %t.ll --untyped-pointers --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: OpCapability UntypedPointers
; CHECK: OpExtension "SPV_KHR_untyped_pointers"

; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypeUntypedPointerKHR StorageBuffer
; CHECK-DAG: [[rta:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[uint]]
; CHECK-DAG: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta]]
; CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpUntypedVariableKHR [[ptr]] StorageBuffer [[block]]

; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpUntypedAccessChainKHR [[ptr]] [[rta]] [[var]] [[uint_0]]
; CHECK: OpStore [[gep]] [[uint_0]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @test(ptr addrspace(1) writeonly align 4 captures(none) initializes((0, 4)) %data) local_unnamed_addr !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !kernel_arg_name !13 !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr [0 x i32], ptr addrspace(1) %0, i32 0, i32 0
  store i32 0, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })


!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4}
!llvm.ident = !{!5, !6}
!_Z28clspv.entry_point_attributes = !{!7, !8}
!clspv.descriptor.index = !{!9}

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
!10 = !{!"none"}
!11 = !{!"int*"}
!12 = !{!""}
!13 = !{!"data"}
!14 = !{i32 2}

