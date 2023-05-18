; RUN: clspv-opt %s -o %t.ll -producer-out-file %t.spv -spv-version=1.5 --passes=spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.3 %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { { i32, i32 } }
%struct.image_kernel_data = type { i32, i32, i32, i32, i32 }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define dso_local spir_kernel void @sample_kernel(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %input, ptr addrspace(1) nocapture writeonly align 4 %outData) !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 !push_constants_image_channel !12 {
entry:
  %0 = call target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x %struct.image_kernel_data] } zeroinitializer)
  %call = tail call spir_func i32 @_Z15get_image_width28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %0) #2
  %2 = getelementptr { [0 x %struct.image_kernel_data] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0, i32 0
  store i32 %call, ptr addrspace(1) %2, align 4
  %call1 = tail call spir_func i32 @_Z27get_image_channel_data_type28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %0) #2, !image_getter_push_constant_offset !6
  %3 = getelementptr { [0 x %struct.image_kernel_data] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0, i32 1
  store i32 %call1, ptr addrspace(1) %3, align 4
  %call2 = tail call spir_func i32 @_Z23get_image_channel_order28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) %0) #2, !image_getter_push_constant_offset !13
  %4 = getelementptr { [0 x %struct.image_kernel_data] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0, i32 2
  store i32 %call2, ptr addrspace(1) %4, align 4
  %5 = getelementptr { [0 x %struct.image_kernel_data] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0, i32 3
  store i32 4318, ptr addrspace(1) %5, align 4
  %6 = getelementptr { [0 x %struct.image_kernel_data] }, ptr addrspace(1) %1, i32 0, i32 0, i32 0, i32 4
  store i32 4274, ptr addrspace(1) %6, align 4
  ret void
}

declare spir_func i32 @_Z15get_image_width28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0))
declare spir_func i32 @_Z27get_image_channel_data_type28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0))
declare spir_func i32 @_Z23get_image_channel_order28ocl_image1d_ro.float.sampled(target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0))
declare target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 0, 0, 0, 0, 1, 0, 0, 0))
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x %struct.image_kernel_data] })

!llvm.module.flags = !{!1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!clspv.descriptor.index = !{!6}

!0 = !{i32 8}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 3, i32 0}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 16.0.0 (https://github.com/llvm/llvm-project 50882b4daf77b9d93e025f804b0855c94a83f237)"}
!5 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!6 = !{i32 1}
!7 = !{i32 1, i32 1}
!8 = !{!"read_only", !"none"}
!9 = !{!"image1d_t", !"image_kernel_data*"}
!10 = !{!"", !""}
!11 = !{i32 3}
!12 = !{i32 0, i32 1, i32 1, i32 0, i32 0, i32 0}
!13 = !{i32 0}

