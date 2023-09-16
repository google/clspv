; RUN: clspv-opt %s -o %t.ll --passes=fixup-builtins -hack-image1d-buffer-bgra
; RUN: FileCheck %s < %t.ll


; CHECK:  [[read:[^ ]+]] = call spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_roi(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 0) %inputA, i32 {{.*}}) #2
; CHECK:  [[shuffle:[^ ]+]] = shufflevector <4 x float> [[read]], <4 x float> poison, <4 x i32> <i32 2, i32 1, i32 0, i32 3>
; CHECK:  [[channel_image_order:[^ ]+]] = call i32 @_Z23get_image_channel_order21ocl_image1d_buffer_ro(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 0) %inputA)
; CHECK:  [[icmp:[^ ]+]] = icmp ne i32 [[channel_image_order]], 4278
; CHECK:  select i1 [[icmp]], <4 x float> [[read]], <4 x float> [[shuffle]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @sample_kernel(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 0) %inputA, target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) %inputB, target("spirv.Sampler") %sampler, ptr addrspace(1) align 4 %results) #0 !kernel_arg_addr_space !14 !kernel_arg_access_qual !15 !kernel_arg_type !16 !kernel_arg_base_type !16 !kernel_arg_type_qual !17 !kernel_arg_name !18 !clspv.pod_args_impl !19 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %call1 = call spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_roi(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 0) %inputA, i32 %0) #2
  %1 = sitofp i32 %0 to float
  %2 = call <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0) %inputB, target("spirv.Sampler") %sampler, float %1)
  %cmp = fcmp une <4 x float> %call1, %2
  %sext = sext <4 x i1> %cmp to <4 x i32>
  %3 = extractelement <4 x i32> %sext, i32 0
  %tobool = icmp ne i32 %3, 0
  br i1 %tobool, label %if.then, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %entry
  %4 = extractelement <4 x i32> %sext, i32 1
  %tobool3 = icmp ne i32 %4, 0
  br i1 %tobool3, label %if.then, label %lor.lhs.false4

lor.lhs.false4:                                   ; preds = %lor.lhs.false
  %5 = extractelement <4 x i32> %sext, i32 2
  %tobool5 = icmp ne i32 %5, 0
  br i1 %tobool5, label %if.then, label %lor.lhs.false6

lor.lhs.false6:                                   ; preds = %lor.lhs.false4
  %6 = extractelement <4 x i32> %sext, i32 3
  %tobool7 = icmp ne i32 %6, 0
  br i1 %tobool7, label %if.then, label %if.else

if.then:                                          ; preds = %lor.lhs.false6, %lor.lhs.false4, %lor.lhs.false, %entry
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %results, i32 %0
  store i32 -1, ptr addrspace(1) %arrayidx, align 4
  br label %if.end

if.else:                                          ; preds = %lor.lhs.false6
  %arrayidx8 = getelementptr inbounds i32, ptr addrspace(1) %results, i32 %0
  store i32 0, ptr addrspace(1) %arrayidx8, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  ret void
}

; Function Attrs: convergent nounwind willreturn memory(read)
declare !kernel_arg_name !20 spir_func <4 x float> @_Z11read_imagef21ocl_image1d_buffer_roi(target("spirv.Image", void, 5, 0, 0, 0, 0, 0, 0), i32) #1

declare <4 x float> @_Z11read_imagef14ocl_image1d_ro11ocl_samplerf(target("spirv.Image", void, 0, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), float)

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind willreturn memory(read) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind willreturn memory(read) "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !5, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7, !8, !9, !10, !11, !12, !13}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 18.0.0 (git@github.com:rjodinchr/llvm-project.git 9dd7a0568c68e41f287de190ae62950d273405c8)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!7 = !{!"_Z4sqrtf", !" __attribute__((overloadable)) __attribute__((const))"}
!8 = !{!"_Z4sqrtDv2_f", !" __attribute__((overloadable)) __attribute__((const))"}
!9 = !{!"_Z4sqrtDv3_f", !" __attribute__((overloadable)) __attribute__((const))"}
!10 = !{!"_Z4sqrtDv4_f", !" __attribute__((overloadable)) __attribute__((const))"}
!11 = !{!"_Z4sqrtDv8_f", !" __attribute__((overloadable)) __attribute__((const))"}
!12 = !{!"_Z4sqrtDv16_f", !" __attribute__((overloadable)) __attribute__((const))"}
!13 = !{!"sample_kernel", !" __kernel"}
!14 = !{i32 1, i32 1, i32 0, i32 1}
!15 = !{!"read_only", !"read_only", !"none", !"none"}
!16 = !{!"image1d_buffer_t", !"image1d_t", !"sampler_t", !"int*"}
!17 = !{!"", !"", !"", !""}
!18 = !{!"inputA", !"inputB", !"sampler", !"results"}
!19 = !{i32 2}
!20 = !{!"", !""}
