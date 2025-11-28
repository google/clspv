; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t.ll

; CHECK: [[i:%[a-zA-Z0-9_.]+]] = phi i32
; CHECK: getelementptr %struct.work_item_data, ptr addrspace(1) %outData, i32 %{{.*}}, i32 1, i32 [[i]]

; UNTYPED: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr inbounds %struct.work_item_data, ptr addrspace(1) %outData, i32
; UNTYPED: [[i:%[a-zA-Z0-9_.]+]] = phi i32
; UNTYPED: getelementptr inbounds i32, ptr addrspace(1) [[gep]], i32 [[i]]

source_filename = "work_item.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, <3 x i32>, <3 x i32>, <3 x i32> }
%struct.work_item_data = type { i32, [3 x i32], [3 x i32], [3 x i32], [3 x i32], [3 x i32], [3 x i32], [3 x i32], [3 x i32] }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__spirv_LocalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkDim = local_unnamed_addr addrspace(8) global i32 0

; Function Attrs: nofree norecurse nounwind memory(read, argmem: readwrite)
define dso_local spir_kernel void @sample_kernel(ptr addrspace(1) writeonly align 4 captures(none) %outData) local_unnamed_addr #0 !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !kernel_arg_name !13 !clspv.pod_args_impl !14 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  %1 = load i32, ptr addrspace(9) getelementptr inbounds nuw (i8, ptr addrspace(9) @__push_constants, i32 32), align 16
  %2 = add i32 %1, %0
  %3 = load i32, ptr addrspace(8) @__spirv_WorkDim, align 4
  %4 = getelementptr %struct.work_item_data, ptr addrspace(1) %outData, i32 %2
  store i32 %3, ptr addrspace(1) %4, align 4
  %cmp.i6.not = icmp eq i32 %3, 0
  br i1 %cmp.i6.not, label %__clang_ocl_kern_imp_sample_kernel.exit, label %for.body.i.lr.ph

for.body.i.lr.ph:                                 ; preds = %entry
  %.split = getelementptr inbounds %struct.work_item_data, ptr addrspace(1) %outData, i32 %2, i32 1
  br label %for.body.i

for.body.i:                                       ; preds = %for.body.i.lr.ph, %for.body.i
  %i.i.07 = phi i32 [ 0, %for.body.i.lr.ph ], [ %inc.i, %for.body.i ]
  %5 = icmp ult i32 %i.i.07, 3
  %6 = select i1 %5, i32 %i.i.07, i32 0
  %7 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 %6
  %8 = load i32, ptr addrspace(9) %7, align 4
  %9 = select i1 %5, i32 %8, i32 1
  %10 = getelementptr inbounds i32, ptr addrspace(1) %.split, i32 %i.i.07
  store i32 %9, ptr addrspace(1) %10, align 4
  %inc.i = add nuw i32 %i.i.07, 1
  %37 = load i32, ptr addrspace(8) @__spirv_WorkDim, align 4
  %cmp.i = icmp ult i32 %inc.i, %37
  br i1 %cmp.i, label %for.body.i, label %__clang_ocl_kern_imp_sample_kernel.exit

__clang_ocl_kern_imp_sample_kernel.exit:          ; preds = %for.body.i, %entry
  ret void
}

attributes #0 = { nofree norecurse nounwind memory(read, argmem: readwrite) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4}
!llvm.ident = !{!5, !6}
!_Z28clspv.entry_point_attributes = !{!7, !8}

!0 = !{i32 1, i32 3, i32 4, i32 5, i32 6}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 3, i32 0}
!5 = !{!"clang version 22.0.0git (https://github.com/llvm/llvm-project af86add989a6156ccff99dd5e0ebd9ab30538d0f)"}
!6 = !{!"clang version 22.0.0git (https://github.com/llvm/llvm-project 4b5f22bd38507675e0e8e490b97af32858b50d81)"}
!7 = !{!"sample_kernel", !"__kernel"}
!8 = !{!"__clang_ocl_kern_imp_sample_kernel", !"__kernel"}
!9 = !{i32 1}
!10 = !{!"none"}
!11 = !{!"work_item_data*"}
!12 = !{!""}
!13 = !{!"outData"}
!14 = !{i32 3}

