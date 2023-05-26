; RUN: clspv-opt --passes=simplify-pointer-bitcast,replace-llvm-intrinsics %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK:  [[gep_inputs:%[^ ]+]] = getelementptr %struct.TestStruct, ptr addrspace(1) %inputs, i32 {{.*}}
; CHECK:  [[or:%[^ ]+]] = or i32 {{.*}}, 1
; CHECK:  [[gep_outputs:%[^ ]+]] = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 [[or]]
; CHECK:  [[gep:%[^ ]+]] = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) [[gep_inputs]], i32 0
; CHECK:  [[load:%[^ ]+]] = load %struct.TestStruct, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[gep:%[^ ]+]] = getelementptr %struct.TestStruct, ptr addrspace(1) [[gep_outputs]], i32 0
; CHECK:  store %struct.TestStruct [[load]], ptr addrspace(1) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }
%struct.TestStruct = type { i16, i16, i32, i8, i8, i16, float }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nounwind memory(read, argmem: readwrite)
define dso_local spir_kernel void @test(ptr addrspace(1) nocapture readonly align 4 %inputs, ptr addrspace(1) nocapture writeonly align 4 %outputs) local_unnamed_addr #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  %1 = load i32, ptr addrspace(9) @__push_constants, align 16
  %2 = add i32 %1, %0
  %mul = shl i32 %2, 1
  %3 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %inputs, i32 %2, i32 0
  %4 = load i16, ptr addrspace(1) %3, align 4
  %5 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %mul, i32 0
  store i16 %4, ptr addrspace(1) %5, align 4
  %6 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %inputs, i32 %2, i32 2
  %7 = load i32, ptr addrspace(1) %6, align 4
  %8 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %mul, i32 2
  store i32 %7, ptr addrspace(1) %8, align 4
  %9 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %inputs, i32 %2, i32 3
  %10 = load i8, ptr addrspace(1) %9, align 4
  %11 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %mul, i32 3
  store i8 %10, ptr addrspace(1) %11, align 4
  %12 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %inputs, i32 %2, i32 5
  %13 = load i16, ptr addrspace(1) %12, align 2
  %14 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %mul, i32 5
  store i16 %13, ptr addrspace(1) %14, align 2
  %15 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %inputs, i32 %2, i32 6
  %16 = load float, ptr addrspace(1) %15, align 4
  %17 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %mul, i32 6
  store float %16, ptr addrspace(1) %17, align 4
  %add9 = or i32 %mul, 1
  %18 = getelementptr inbounds %struct.TestStruct, ptr addrspace(1) %outputs, i32 %add9
  tail call void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noundef align 4 dereferenceable(16) %18, ptr addrspace(1) noundef align 4 dereferenceable(16) %3, i32 16, i1 false)
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) noalias nocapture writeonly, ptr addrspace(1) noalias nocapture readonly, i32, i1 immarg) #1

attributes #0 = { mustprogress nofree norecurse nounwind memory(read, argmem: readwrite) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 2, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project dc95245e69a1c1098a744a2c3af83ca48d9ba495)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = !{i32 1, i32 1}
!8 = !{!"none", !"none"}
!9 = !{!"TestStruct*", !"TestStruct*"}
!10 = !{!"const", !""}
!11 = !{i32 3}
