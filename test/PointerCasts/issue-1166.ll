; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[gep:%[^ ]+]] = getelementptr %struct.S, ptr addrspace(1) %s, i32 0, i32 0
; CHECK:  store i64 8000000000, ptr addrspace(1) [[gep]], align 8
; CHECK:  [[gep:%[^ ]+]] = getelementptr inbounds %struct.S, ptr addrspace(1) %s, i32 0, i32 1
; CHECK:  store i32 77, ptr addrspace(1) [[gep]], align 8
; CHECK:  [[gep:%[^ ]+]] = getelementptr inbounds %struct.S, ptr addrspace(1) %s, i32 0, i32 2
; CHECK:  store i32 88, ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { i64, i32, i32 }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write)
define dso_local spir_kernel void @Kernel(ptr addrspace(1) nocapture writeonly align 8 %s) local_unnamed_addr #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !kernel_arg_name !11 !clspv.pod_args_impl !12 {
entry:
  store i64 8000000000, ptr addrspace(1) %s, align 8
  %i2 = getelementptr inbounds %struct.S, ptr addrspace(1) %s, i32 0, i32 1
  store i32 77, ptr addrspace(1) %i2, align 8
  %i3 = getelementptr inbounds %struct.S, ptr addrspace(1) %s, i32 0, i32 2
  store i32 88, ptr addrspace(1) %i3, align 4
  ret void
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!_Z28clspv.entry_point_attributes = !{!6}

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
