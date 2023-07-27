; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer --producer-out-file=%t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env spv1.0
; RUN: FileCheck %s < %t.spvasm

; CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
; CHECK: [[ulong:%[^ ]+]] = OpTypeInt 64 0
; CHECK: [[ulong_8000000000:%[^ ]+]] = OpConstant [[ulong]] 8000000000

; CHECK: Bitcast [[uint2]] [[ulong_8000000000]]
; CHECK: Bitcast [[uint2]] [[ulong_8000000000]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write)
define dso_local spir_kernel void @Kernel(ptr addrspace(1) nocapture writeonly align 8 %s) local_unnamed_addr #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !kernel_arg_name !11 !clspv.pod_args_impl !12 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = bitcast <1 x i64> <i64 8000000000> to <2 x i32>
  %3 = extractelement <2 x i32> %2, i64 0
  store i32 %3, ptr addrspace(1) %1, align 4
  %4 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %5 = bitcast <1 x i64> <i64 8000000000> to <2 x i32>
  %6 = extractelement <2 x i32> %5, i64 1
  store i32 %6, ptr addrspace(1) %4, align 4
  %7 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 2
  store i32 77, ptr addrspace(1) %7, align 8
  %8 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 3
  store i32 88, ptr addrspace(1) %8, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!_Z28clspv.entry_point_attributes = !{!6}
!clspv.descriptor.index = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!6 = !{!"Kernel", !" kernel"}
!7 = !{i32 1}
!8 = !{!"none"}
!9 = !{!"struct S*"}
!10 = !{!""}
!11 = !{!"s"}
!12 = !{i32 2}
