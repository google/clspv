; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK:  [[base_offset:%[^ ]+]] = add i32 {{.*}}, 2
; CHECK:  [[base_offset_hi:%[^ ]+]] = lshr i32 [[base_offset]], 1
; CHECK:  [[base_offset_lo:%[^ ]+]] = and i32 [[base_offset]], 1
; CHECK:  [[gep_lo:%[^ ]+]] = getelementptr [0 x <2 x i8>], ptr addrspace(3) {{.*}}, i32 0, i32 [[base_offset_hi]], i32 [[base_offset_lo]]
; CHECK:  store i8 {{.*}}, ptr addrspace(3) [[gep_lo]], align 1
; CHECK:  [[shl:%[^ ]+]] = shl i32 [[base_offset_hi]], 1
; CHECK:  [[add:%[^ ]+]] = add i32 [[shl]], [[base_offset_lo]]
; CHECK:  [[base_offset:%[^ ]+]] = add i32 [[add]], 1
; CHECK:  [[base_offset_hi:%[^ ]+]] = lshr i32 [[base_offset]], 1
; CHECK:  [[base_offset_lo:%[^ ]+]] = and i32 [[base_offset]], 1
; CHECK:  [[gep_hi:%[^ ]+]] = getelementptr [0 x <2 x i8>], ptr addrspace(3) {{.*}}, i32 0, i32 [[base_offset_hi]], i32 [[base_offset_lo]]
; CHECK:  store i8 {{.*}}, ptr addrspace(3) [[gep_hi]], align 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, %1 }
%1 = type { i32 }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @test_fn(ptr addrspace(3) nocapture align 2 %sSharedStorage, ptr addrspace(1) nocapture readnone align 2 %srcValues, ptr addrspace(1) nocapture readonly align 4 %offsets, ptr addrspace(1) nocapture readnone align 2 %destBuffer) local_unnamed_addr #0 !kernel_arg_addr_space !14 !kernel_arg_access_qual !15 !kernel_arg_type !16 !kernel_arg_base_type !17 !kernel_arg_type_qual !18 !kernel_arg_name !19 !clspv.pod_args_impl !20 !kernel_arg_map !21 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x <2 x i8>] zeroinitializer)
  %1 = getelementptr [0 x <2 x i8>], ptr addrspace(3) %0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 1, i32 0, i32 0, { [0 x <2 x i8>] } zeroinitializer)
  %3 = getelementptr { [0 x <2 x i8>] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 2, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %5 = getelementptr { [0 x i32] }, ptr addrspace(1) %4, i32 0, i32 0, i32 0
  %6 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 3, i32 2, i32 0, { [0 x <2 x i8>] } zeroinitializer)
  %7 = getelementptr { [0 x <2 x i8>] }, ptr addrspace(1) %6, i32 0, i32 0, i32 0
  %8 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %9 = load i32, ptr addrspace(5) %8, align 16
  %10 = getelementptr %0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0
  %11 = load i32, ptr addrspace(9) %10, align 16
  %12 = add i32 %9, %11
  %13 = getelementptr i32, ptr addrspace(1) %5, i32 %12
  %14 = load i32, ptr addrspace(1) %13, align 4
  %arrayidx1.i = getelementptr inbounds <2 x i8>, ptr addrspace(3) %1, i32 %14
  store <2 x i8> zeroinitializer, ptr addrspace(3) %arrayidx1.i, align 2
  %15 = load i32, ptr addrspace(1) %13, align 4
  %arrayidx3.i = getelementptr inbounds <2 x i8>, ptr addrspace(3) %1, i32 %15
  %16 = load <2 x i8>, ptr addrspace(3) %arrayidx3.i, align 2
  %17 = shl i32 %15, 1
  %18 = add i32 %17, 2
  %19 = lshr i32 %18, 1
  %20 = and i32 %18, 1
  %21 = getelementptr <2 x i8>, ptr addrspace(3) %1, i32 %19, i32 %20
  %22 = extractelement <2 x i8> %16, i64 0
  %23 = extractelement <2 x i8> %16, i64 1
  %24 = getelementptr i8, ptr addrspace(3) %21, i32 0
  store i8 %22, ptr addrspace(3) %24, align 1
  %25 = getelementptr i8, ptr addrspace(3) %21, i32 1
  store i8 %23, ptr addrspace(3) %25, align 1
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #2
  ret void
}

; Function Attrs: convergent noduplicate
declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) local_unnamed_addr #1

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x i8>] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x <2 x i8>] })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x <2 x i8>])

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent noduplicate }
attributes #2 = { nounwind }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !7, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8}
!_Z28clspv.entry_point_attributes = !{!9}
!clspv.descriptor.index = !{!10}
!clspv.next_spec_constant_id = !{!11}
!clspv.spec_constant_list = !{!12}
!_Z20clspv.local_spec_ids = !{!13}

!0 = !{i32 1, i32 4, i32 7}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 3, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 19.0.0git (https://github.com/llvm/llvm-project 2960656eb909b5361ce2c3f641ee341769076ab7)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!8 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!9 = !{!"test_fn", !" __kernel"}
!10 = !{i32 1}
!11 = distinct !{i32 4}
!12 = !{i32 3, i32 3}
!13 = !{ptr @test_fn, i32 0, i32 3}
!14 = !{i32 3, i32 1, i32 1, i32 1, i32 0}
!15 = !{!"none", !"none", !"none", !"none", !"none"}
!16 = !{!"char2*", !"char2*", !"uint*", !"char2*", !"uint"}
!17 = !{!"char __attribute__((ext_vector_type(2)))*", !"char __attribute__((ext_vector_type(2)))*", !"uint*", !"char __attribute__((ext_vector_type(2)))*", !"uint"}
!18 = !{!"", !"", !"", !"", !""}
!19 = !{!"sSharedStorage", !"srcValues", !"offsets", !"destBuffer", !"alignmentOffset"}
!20 = !{i32 3}
!21 = !{!22, !23, !24, !25, !26}
!22 = !{!"sSharedStorage", i32 0, i32 0, i32 0, i32 0, !"local"}
!23 = !{!"srcValues", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!24 = !{!"offsets", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!25 = !{!"destBuffer", i32 3, i32 3, i32 0, i32 0, !"buffer"}
!26 = !{!"alignmentOffset", i32 4, i32 -1, i32 32, i32 4, !"pod_pushconstant"}
