; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv --target-env spv1.0

; CHECK: [[uint_40:%[^ ]+]] = OpConstant {{.*}} 40
; CHECK: [[variable:%[^ ]+]] = OpVariable {{.*}} Workgroup
; CHECK: OpExtInst {{.*}} {{.*}} WorkgroupVariableSize [[variable]] [[uint_40]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@local_memory_kernel.array = internal unnamed_addr addrspace(3) global [10 x i32] undef, align 4
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @local_memory_kernel(ptr addrspace(1) writeonly align 4 captures(none) %data) local_unnamed_addr #0 !kernel_arg_addr_space !6 !kernel_arg_access_qual !7 !kernel_arg_type !8 !kernel_arg_base_type !8 !kernel_arg_type_qual !9 !kernel_arg_name !10 !clspv.pod_args_impl !11 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %2 = load i32, ptr addrspace(5) %1, align 16
  %arrayidx = getelementptr inbounds nuw [10 x i32], ptr addrspace(3) @local_memory_kernel.array, i32 0, i32 %2
  store i32 %2, ptr addrspace(3) %arrayidx, align 4
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #2
  %3 = load i32, ptr addrspace(3) %arrayidx, align 4
  %add = add i32 %2, 1
  %arrayidx2 = getelementptr inbounds nuw [10 x i32], ptr addrspace(3) @local_memory_kernel.array, i32 0, i32 %add
  %4 = load i32, ptr addrspace(3) %arrayidx2, align 4
  %add3 = add nsw i32 %4, %3
  %5 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 %2
  store i32 %add3, ptr addrspace(1) %5, align 4
  ret void
}

; Function Attrs: convergent noduplicate
declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) local_unnamed_addr #1

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent noduplicate }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!_Z28clspv.entry_point_attributes = !{!5}
!clspv.descriptor.index = !{!6}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 21.0.0git (https://github.com/llvm/llvm-project 226b778a5eaf9355e473e5b3a34150de4ef488b9)"}
!5 = !{!"local_memory_kernel", !"__kernel"}
!6 = !{i32 1}
!7 = !{!"none"}
!8 = !{!"int*"}
!9 = !{!""}
!10 = !{!"data"}
!11 = !{i32 2}
