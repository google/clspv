; RUN: clspv-opt %s -o %t.ll --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t.ll

; CHECK:  [[sampler:%[^ ]+]] = call target("spirv.Sampler") @__translate_sampler_initializer(i32 21)
; CHECK:  [[convert:%[^ ]+]] = sitofp <4 x i32> <i32 2, i32 3, i32 4, i32 5> to <4 x float>
; CHECK:  [[sizes:%[^ ]+]] = call <4 x float> @clspv.get_image_sizes(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img)
; CHECK:  [[div:%[^ ]+]] = fdiv <4 x float> [[convert]], [[sizes]]
; CHECK:  call <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") [[sampler]], <4 x float> [[div]])


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @foo(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, ptr addrspace(1) align 16 %out, { i32 } %podargs) #0 !kernel_arg_addr_space !8 !kernel_arg_access_qual !9 !kernel_arg_type !10 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !kernel_arg_name !13 !clspv.pod_args_impl !14 !kernel_arg_map !15 {
entry:
  %i = extractvalue { i32 } %podargs, 0
  %0 = call spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32 20) #3
  %call.i = call spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %0, <4 x i32> <i32 2, i32 3, i32 4, i32 5>) #4
  store <4 x float> %call.i, ptr addrspace(1) %out, align 16
  ret void
}

; Function Attrs: convergent nounwind willreturn memory(read)
declare !kernel_arg_name !12 spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), <4 x i32>) #1

; Function Attrs: speculatable memory(none)
declare !kernel_arg_name !19 spir_func target("spirv.Sampler") @__translate_sampler_initializer(i32) #2

attributes #0 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind willreturn memory(read) "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { speculatable memory(none) }
attributes #3 = { nounwind }
attributes #4 = { convergent nobuiltin nounwind willreturn memory(read) "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !5, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 51e93736bb997a11ab4026e6a54bc89e0950df06)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!7 = !{!"foo", !" kernel"}
!8 = !{i32 1, i32 1, i32 0}
!9 = !{!"read_only", !"none", !"none"}
!10 = !{!"image3d_t", !"float4*", !"int"}
!11 = !{!"image3d_t", !"float __attribute__((ext_vector_type(4)))*", !"int"}
!12 = !{!"", !"", !""}
!13 = !{!"img", !"out", !"i"}
!14 = !{i32 2}
!15 = !{!16, !17, !18}
!16 = !{!"img", i32 0, i32 0, i32 0, i32 0, !"ro_image"}
!17 = !{!"out", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!18 = !{!"i", i32 2, i32 2, i32 0, i32 4, !"pod_pushconstant"}
!19 = !{!""}
