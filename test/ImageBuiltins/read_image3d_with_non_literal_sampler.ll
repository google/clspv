; RUN: clspv-opt %s -o %t.ll --passes=set-image-metadata
; RUN: FileCheck %s < %t.ll

; CHECK:  [[coord:%[^ ]+]] = sitofp <4 x i32> {{.*}} to <4 x float>
; CHECK:  [[image_dim:%[^ ]+]] = call <4 x i32> @_Z13get_image_dim11ocl_image3d(target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) %0)
; CHECK:  [[convert:%[^ ]+]] = sitofp <4 x i32> [[image_dim]] to <4 x float>
; CHECK:  [[floor:%[^ ]+]] = call <4 x float> @floor(<4 x float> [[coord]])
; CHECK:  [[fadd:%[^ ]+]] = fadd <4 x float> [[floor]], splat (float 5.000000e-01)
; CHECK:  [[fdiv_nearest:%[^ ]+]] = fdiv <4 x float> [[fadd]], [[convert]]
; CHECK:  [[fdiv_linear:%[^ ]+]] = fdiv <4 x float> [[coord]], [[convert]]
; CHECK:  [[sampler_mask:%[^ ]+]] = call i32 @clspv.get_normalized_sampler_mask(), !sampler_mask_push_constant_offset !29
; CHECK:  [[and:%[^ ]+]] = and i32 [[sampler_mask]], 48
; CHECK:  [[cmp:%[^ ]+]] = icmp eq i32 [[and]], 16
; CHECK:  [[insert:%[^ ]+]] = insertelement <4 x i1> poison, i1 [[cmp]], i64 0
; CHECK:  [[shuffle:%[^ ]+]] = shufflevector <4 x i1> [[insert]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK:  [[select:%[^ ]+]] = select <4 x i1> [[shuffle]], <4 x float> [[fdiv_nearest]], <4 x float> [[fdiv_linear]]
; CHECK:  [[and:%[^ ]+]] = and i32 [[sampler_mask]], 1
; CHECK:  [[cmp:%[^ ]+]] = icmp eq i32 [[and]], 1
; CHECK:  [[insert:%[^ ]+]] = insertelement <4 x i1> poison, i1 [[cmp]], i64 0
; CHECK:  [[shuffle:%[^ ]+]] = shufflevector <4 x i1> [[insert]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK:  [[new_coord:%[^ ]+]] = select <4 x i1> [[shuffle]], <4 x float> [[coord]], <4 x float> [[select]]
; CHECK:  tail call <4 x float> @_Z11read_imagef30ocl_image3d_ro_t.float.sampled11ocl_samplerDv4_f(target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %1, <4 x float> [[new_coord]]) #2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { %1 }
%1 = type { i32, i32, i32, i32 }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

declare <4 x float> @_Z11read_imagef30ocl_image3d_ro_t.float.sampled11ocl_samplerDv4_f(target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0), target("spirv.Sampler"), <4 x float>)

; Function Attrs: norecurse nounwind
define spir_kernel void @foo(target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) %img, target("spirv.Sampler") %sampler, ptr addrspace(1) nocapture writeonly align 16 %out) #0 !kernel_arg_addr_space !16 !kernel_arg_access_qual !17 !kernel_arg_type !18 !kernel_arg_base_type !19 !kernel_arg_type_qual !20 !kernel_arg_name !21 !clspv.pod_args_impl !22 !kernel_arg_map !23 {
entry:
  %0 = call target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) undef)
  %1 = call target("spirv.Sampler") @_Z14clspv.resource.1(i32 0, i32 1, i32 8, i32 1, i32 1, i32 0, target("spirv.Sampler") zeroinitializer)
  %2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %3 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = getelementptr %0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 0
  %5 = load i32, ptr addrspace(9) %4, align 8
  %6 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 1
  %7 = load i32, ptr addrspace(9) %6, align 4
  %8 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 2
  %9 = load i32, ptr addrspace(9) %8, align 8
  %10 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 3
  %11 = load i32, ptr addrspace(9) %10, align 4
  %12 = call <4 x i32> @_Z25clspv.composite_construct.0(i32 %5, i32 %7, i32 %9, i32 %11)
  %13 = sitofp <4 x i32> %12 to <4 x float>
  %14 = tail call <4 x float> @_Z11read_imagef30ocl_image3d_ro_t.float.sampled11ocl_samplerDv4_f(target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) %0, target("spirv.Sampler") %1, <4 x float> %13) #2
  store <4 x float> %14, ptr addrspace(1) %3, align 16
  ret void
}

declare target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 2, 0, 0, 0, 1, 0, 0, 0))

declare target("spirv.Sampler") @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Sampler"))

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

; Function Attrs: memory(read)
declare <4 x i32> @_Z25clspv.composite_construct.0(i32, i32, i32, i32) #1

attributes #0 = { norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { memory(read) }
attributes #2 = { nounwind }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !6, !6, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7}
!_Z28clspv.entry_point_attributes = !{!8, !9, !10, !11, !12, !13, !14}
!clspv.descriptor.index = !{!15}

!0 = !{i32 7}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 18.0.0 (git@github.com:rjodinchr/llvm-project.git 9dd7a0568c68e41f287de190ae62950d273405c8)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!8 = !{!"_Z4sqrtf", !" __attribute__((overloadable)) __attribute__((const))"}
!9 = !{!"_Z4sqrtDv2_f", !" __attribute__((overloadable)) __attribute__((const))"}
!10 = !{!"_Z4sqrtDv3_f", !" __attribute__((overloadable)) __attribute__((const))"}
!11 = !{!"_Z4sqrtDv4_f", !" __attribute__((overloadable)) __attribute__((const))"}
!12 = !{!"_Z4sqrtDv8_f", !" __attribute__((overloadable)) __attribute__((const))"}
!13 = !{!"_Z4sqrtDv16_f", !" __attribute__((overloadable)) __attribute__((const))"}
!14 = !{!"foo", !" kernel"}
!15 = !{i32 1}
!16 = !{i32 1, i32 0, i32 1, i32 0}
!17 = !{!"read_only", !"none", !"none", !"none"}
!18 = !{!"image3d_t", !"sampler_t", !"float4*", !"int4"}
!19 = !{!"image3d_t", !"sampler_t", !"float __attribute__((ext_vector_type(4)))*", !"int __attribute__((ext_vector_type(4)))"}
!20 = !{!"", !"", !"", !""}
!21 = !{!"img", !"sampler", !"out", !"coord"}
!22 = !{i32 3}
!23 = !{!24, !25, !26, !27}
!24 = !{!"img", i32 0, i32 0, i32 0, i32 0, !"ro_image"}
!25 = !{!"sampler", i32 1, i32 1, i32 0, i32 0, !"sampler"}
!26 = !{!"out", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!27 = !{!"coord", i32 3, i32 -1, i32 0, i32 16, !"pod_pushconstant"}
