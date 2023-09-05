; RUN: clspv-opt %s -o %t.ll --passes=inline-func-with-read-image3d-non-literal-sampler
; RUN: FileCheck %s < %t.ll

; CHECK-NOT: call spirv-func <4 x float> @bar

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_func <4 x float> @bar(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler) #0 !kernel_arg_name !14 {
entry:
  %0 = call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler, <4 x float> <float 0.000000e+00, float 1.000000e+00, float 2.000000e+00, float 3.000000e+00>) #2
  ret <4 x float> %0
}

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @foo(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler, ptr addrspace(1) align 16 %out) #1 !kernel_arg_addr_space !15 !kernel_arg_access_qual !16 !kernel_arg_type !17 !kernel_arg_base_type !18 !kernel_arg_type_qual !19 !kernel_arg_name !20 !clspv.pod_args_impl !21 {
entry:
  %call = call spir_func <4 x float> @bar(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler) #3
  store <4 x float> %call, ptr addrspace(1) %out, align 16
  ret void
}

declare <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), <4 x float>)

attributes #0 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #1 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #2 = { nounwind }
attributes #3 = { convergent nobuiltin nounwind "no-builtins" }

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
!13 = !{!"foo", !" kernel"}
!14 = !{!"img", !"sampler"}
!15 = !{i32 1, i32 0, i32 1}
!16 = !{!"read_only", !"none", !"none"}
!17 = !{!"image3d_t", !"sampler_t", !"float4*"}
!18 = !{!"image3d_t", !"sampler_t", !"float __attribute__((ext_vector_type(4)))*"}
!19 = !{!"", !"", !""}
!20 = !{!"img", !"sampler", !"out"}
!21 = !{i32 3}
