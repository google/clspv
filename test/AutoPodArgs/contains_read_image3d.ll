; RUN: clspv-opt %s -o %t.ll --passes=auto-pod-args
; RUN: FileCheck %s < %t.ll

; CHECK: define dso_local spir_kernel void @foo(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler, ptr addrspace(1) align 16 %out, <4 x i32> %coord)
; CHECK-SAME: !clspv.pod_args_impl [[MD:![^ ]+]]
; CHECK: [[MD]] = !{i32 3}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent norecurse nounwind
define dso_local spir_func <4 x float> @bar(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler, <4 x i32> %coord) #0 !kernel_arg_name !14 {
entry:
  %img.addr = alloca target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), align 4
  store target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) zeroinitializer, ptr %img.addr, align 4
  %sampler.addr = alloca target("spirv.Sampler"), align 4
  store target("spirv.Sampler") zeroinitializer, ptr %sampler.addr, align 4
  %coord.addr = alloca <4 x i32>, align 16
  store <4 x i32> zeroinitializer, ptr %coord.addr, align 16
  store target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, ptr %img.addr, align 4
  store target("spirv.Sampler") %sampler, ptr %sampler.addr, align 4
  store <4 x i32> %coord, ptr %coord.addr, align 16
  %0 = load target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), ptr %img.addr, align 4
  %1 = load target("spirv.Sampler"), ptr %sampler.addr, align 4
  %2 = load <4 x i32>, ptr %coord.addr, align 16
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %0, target("spirv.Sampler") %1, <4 x i32> %2) #3
  ret <4 x float> %call
}

; Function Attrs: convergent nounwind willreturn memory(read)
declare !kernel_arg_name !17 spir_func <4 x float> @_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), target("spirv.Sampler"), <4 x i32>) #1

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @foo(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, target("spirv.Sampler") %sampler, ptr addrspace(1) align 16 %out, <4 x i32> %coord) #2 !kernel_arg_name !16 !kernel_arg_addr_space !17 !kernel_arg_access_qual !18 !kernel_arg_type !19 !kernel_arg_base_type !20 !kernel_arg_type_qual !21 {
entry:
  %img.addr = alloca target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), align 4
  store target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) zeroinitializer, ptr %img.addr, align 4
  %sampler.addr = alloca target("spirv.Sampler"), align 4
  store target("spirv.Sampler") zeroinitializer, ptr %sampler.addr, align 4
  %out.addr = alloca ptr addrspace(1), align 4
  store ptr addrspace(1) null, ptr %out.addr, align 4
  %coord.addr = alloca <4 x i32>, align 16
  store <4 x i32> zeroinitializer, ptr %coord.addr, align 16
  store target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %img, ptr %img.addr, align 4
  store target("spirv.Sampler") %sampler, ptr %sampler.addr, align 4
  store ptr addrspace(1) %out, ptr %out.addr, align 4
  store <4 x i32> %coord, ptr %coord.addr, align 16
  %0 = load target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0), ptr %img.addr, align 4
  %1 = load target("spirv.Sampler"), ptr %sampler.addr, align 4
  %2 = load <4 x i32>, ptr %coord.addr, align 16
  %call = call spir_func <4 x float> @bar(target("spirv.Image", void, 2, 0, 0, 0, 0, 0, 0) %0, target("spirv.Sampler") %1, <4 x i32> %2) #4
  %3 = load ptr addrspace(1), ptr %out.addr, align 4
  store <4 x float> %call, ptr addrspace(1) %3, align 16
  ret void
}

attributes #0 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #1 = { convergent nounwind willreturn memory(read) "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #3 = { convergent nobuiltin nounwind willreturn memory(read) "no-builtins" }
attributes #4 = { convergent nobuiltin nounwind "no-builtins" }

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
!14 = !{!"img", !"sampler", !"coord"}
!15 = !{!"", !"", !""}
!16 = !{!"img", !"sampler", !"out", !"coord"}
!17 = !{i32 1, i32 0, i32 1, i32 0}
!18 = !{!"read_only", !"none", !"none", !"none"}
!19 = !{!"image3d_t", !"sampler_t", !"float4*", !"int4"}
!20 = !{!"image3d_t", !"sampler_t", !"float __attribute__((ext_vector_type(4)))*", !"int __attribute__((ext_vector_type(4)))"}
!21 = !{!"", !"", !"", !""}
