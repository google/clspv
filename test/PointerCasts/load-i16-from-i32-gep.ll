; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[load:%[^ ]+]] = load i16, ptr addrspace(1) %source, align 2
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x i16> <i16 poison, i16 0>, i16 [[load]], i64 0
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i16>, ptr addrspace(1) %dest, i32 0
; CHECK:  store <2 x i16> [[insert]], ptr addrspace(1) [[gep]], align 4

; CHECK:  [[gep:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %source, i32 1
; CHECK:  [[load:%[^ ]+]] = load i16, ptr addrspace(1) [[gep]], align 2
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x i16> <i16 0, i16 poison>, i16 [[load]], i64 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i16>, ptr addrspace(1) %dest, i32 1
; CHECK:  store <2 x i16> [[insert]], ptr addrspace(1) [[gep]], align 4

; CHECK:  [[gep:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %source, i32 2
; CHECK:  [[load:%[^ ]+]] = load i16, ptr addrspace(1) [[gep]], align 2
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x i16> <i16 0, i16 poison>, i16 [[load]], i64 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i16>, ptr addrspace(1) %dest, i32 2
; CHECK:  store <2 x i16> [[insert]], ptr addrspace(1) [[gep]], align 4

; CHECK:  [[gep:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %source, i32 3
; CHECK:  [[load:%[^ ]+]] = load i16, ptr addrspace(1) [[gep]], align 2
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x i16> <i16 0, i16 poison>, i16 [[load]], i64 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i16>, ptr addrspace(1) %dest, i32 3
; CHECK:  store <2 x i16> [[insert]], ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: nofree norecurse nounwind memory(read, argmem: readwrite)
define dso_local spir_kernel void @sample_test(ptr addrspace(1) nocapture readonly align 2 %source, ptr addrspace(1) nocapture writeonly align 4 %dest) local_unnamed_addr #0 !kernel_arg_addr_space !10 !kernel_arg_access_qual !11 !kernel_arg_type !12 !kernel_arg_base_type !13 !kernel_arg_type_qual !14 !kernel_arg_name !15 !clspv.pod_args_impl !16 {
entry:
  %0 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %1 = load i32, ptr addrspace(5) %0, align 16
  %2 = getelementptr %0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0
  %3 = load i32, ptr addrspace(9) %2, align 16
  %4 = sub i32 0, %3
  %cmp.not = icmp eq i32 %1, %4
  br i1 %cmp.not, label %if.end, label %return

if.end:                                           ; preds = %entry
  %5 = load i16, ptr addrspace(1) %source, align 2
  %6 = insertelement <2 x i16> <i16 poison, i16 0>, i16 %5, i64 0
  %7 = getelementptr <2 x i16>, ptr addrspace(1) %dest, i32 0
  store <2 x i16> %6, ptr addrspace(1) %7, align 4
  %8 = getelementptr i16, ptr addrspace(1) %source, i32 1
  %9 = load i16, ptr addrspace(1) %8, align 2
  %10 = insertelement <2 x i16> <i16 0, i16 poison>, i16 %9, i64 1
  %arrayidx3 = getelementptr inbounds i8, ptr addrspace(1) %dest, i32 4
  store <2 x i16> %10, ptr addrspace(1) %arrayidx3, align 4
  %11 = getelementptr i32, ptr addrspace(1) %source, i32 1
  %12 = load i16, ptr addrspace(1) %11, align 2
  %13 = insertelement <2 x i16> <i16 0, i16 poison>, i16 %12, i64 1
  %arrayidx5 = getelementptr inbounds i8, ptr addrspace(1) %dest, i32 8
  store <2 x i16> %13, ptr addrspace(1) %arrayidx5, align 4
  %14 = getelementptr i16, ptr addrspace(1) %source, i32 3
  %15 = load i16, ptr addrspace(1) %14, align 2
  %16 = insertelement <2 x i16> <i16 0, i16 poison>, i16 %15, i64 1
  %arrayidx7 = getelementptr inbounds i8, ptr addrspace(1) %dest, i32 12
  store <2 x i16> %16, ptr addrspace(1) %arrayidx7, align 4
  br label %return

return:                                           ; preds = %if.end, %entry
  ret void
}

attributes #0 = { nofree norecurse nounwind memory(read, argmem: readwrite) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !7, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8}
!_Z28clspv.entry_point_attributes = !{!9}

!0 = !{i32 1, i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 3, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 19.0.0git (https://github.com/llvm/llvm-project 2960656eb909b5361ce2c3f641ee341769076ab7)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!8 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!9 = !{!"sample_test", !" __kernel"}
!10 = !{i32 1, i32 1}
!11 = !{!"none", !"none"}
!12 = !{!"short*", !"short2*"}
!13 = !{!"short*", !"short __attribute__((ext_vector_type(2)))*"}
!14 = !{!"", !""}
!15 = !{!"source", !"dest"}
!16 = !{i32 3}
