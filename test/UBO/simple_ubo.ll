; RUN: clspv-opt %s -o %t.ll --physical-storage-buffers --passes=spirv-producer --producer-out-file=%t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val %t.spv --target-env spv1.6

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, %1 }
%1 = type { i32, i32, i32, i32 }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

; Function Attrs: nofree norecurse nounwind memory(readwrite, inaccessiblemem: read)
define spir_kernel void @test_simple() local_unnamed_addr #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !10 !kernel_arg_type_qual !11 !kernel_arg_name !12 !clspv.pod_args_impl !13 !kernel_arg_map !14 {
entry:
  %0 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i64 0, i32 2, i32 0
  %1 = load i32, ptr addrspace(9) %0, align 16
  %2 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i64 0, i32 2, i32 1
  %3 = load i32, ptr addrspace(9) %2, align 4
  %4 = zext i32 %1 to i64
  %5 = zext i32 %3 to i64
  %6 = shl nuw i64 %5, 32
  %7 = or i64 %6, %4
  %8 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i64 0, i32 2, i32 2
  %9 = load i32, ptr addrspace(9) %8, align 8
  %10 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i64 0, i32 2, i32 3
  %11 = load i32, ptr addrspace(9) %10, align 4
  %12 = zext i32 %9 to i64
  %13 = zext i32 %11 to i64
  %14 = shl nuw i64 %13, 32
  %15 = or i64 %14, %12
  %16 = inttoptr i64 %7 to ptr addrspace(1), !clspv.pointer_from_pod !17
  %17 = inttoptr i64 %15 to ptr addrspace(2), !clspv.pointer_from_pod !17
  %18 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %19 = load i32, ptr addrspace(5) %18, align 16
  %20 = zext i32 %19 to i64
  %21 = getelementptr %0, ptr addrspace(9) @__push_constants, i64 0, i32 1, i64 0
  %22 = load i32, ptr addrspace(9) %21, align 16
  %23 = zext i32 %22 to i64
  %24 = add nuw nsw i64 %23, %20
  %conv.i.i = trunc i64 %24 to i32
  %vecinit.i.i = insertelement <4 x i32> undef, i32 %conv.i.i, i64 0
  %vecinit6.i.i = shufflevector <4 x i32> %vecinit.i.i, <4 x i32> poison, <4 x i32> zeroinitializer
  %arrayidx.i.i = getelementptr inbounds <4 x i32>, ptr addrspace(2) %17, i64 %24
  %25 = load <4 x i32>, ptr addrspace(2) %arrayidx.i.i, align 16
  %add.i.i = add <4 x i32> %vecinit6.i.i, %25
  %arrayidx7.i.i = getelementptr inbounds <4 x i32>, ptr addrspace(1) %16, i64 %24
  store <4 x i32> %add.i.i, ptr addrspace(1) %arrayidx7.i.i, align 16
  ret void
}

attributes #0 = { nofree norecurse nounwind memory(readwrite, inaccessiblemem: read) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7}

!0 = !{i32 1, i32 4, i32 7}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!7 = !{!"test_simple", !" kernel"}
!8 = !{!"none", !"none"}
!9 = !{!"uint4*", !"uint4*"}
!10 = !{!"uint __attribute__((ext_vector_type(4)))*", !"uint __attribute__((ext_vector_type(4)))*"}
!11 = !{!"", !"const"}
!12 = !{!"out", !"c_data"}
!13 = !{i32 3}
!14 = !{!15, !16}
!15 = !{!"", i32 0, i32 -1, i32 32, i32 8, !"pointer_pushconstant"}
!16 = !{!"", i32 1, i32 -1, i32 40, i32 8, !"pointer_pushconstant"}
!17 = !{}

