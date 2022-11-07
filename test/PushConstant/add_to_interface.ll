; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @bitwise_and(i8 addrspace(1)* nocapture readonly align 1 %a, i8 addrspace(1)* nocapture readonly align 1 %b, i8 addrspace(1)* nocapture writeonly align 1 %out) local_unnamed_addr #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !0 {
entry:
  %0 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i8] } zeroinitializer)
  %1 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i8] } zeroinitializer)
  %2 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i8] } zeroinitializer)
  %3 = getelementptr <3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i32 0, i32 0
  %4 = load i32, i32 addrspace(5)* %3, align 16
  %5 = getelementptr inbounds %0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0
  %6 = load i32, i32 addrspace(9)* %5, align 16
  %7 = add i32 %6, %4
  %8 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %0, i32 0, i32 0, i32 %7
  %9 = load i8, i8 addrspace(1)* %8, align 1
  %10 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %1, i32 0, i32 0, i32 %7
  %11 = load i8, i8 addrspace(1)* %10, align 1
  %and5 = and i8 %11, %9
  %12 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %2, i32 0, i32 0, i32 %7
  store i8 %and5, i8 addrspace(1)* %12, align 1
  ret void
}

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x i8] })

attributes #0 = { nofree norecurse nounwind memory(read, argmem: readwrite) "frame-pointer"="none" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2}
!llvm.ident = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!clspv.descriptor.index = !{!0}

!0 = !{i32 1}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 1, i32 2}
!3 = !{!"clang version 16.0.0 (https://github.com/llvm/llvm-project b6cf94e973f9659086633ca56dc51bc74d4125eb)"}
!4 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!5 = !{i32 1, i32 1, i32 1}
!6 = !{!"none", !"none", !"none"}
!7 = !{!"uchar*", !"uchar*", !"uchar*"}
!8 = !{!"const", !"const", !""}

