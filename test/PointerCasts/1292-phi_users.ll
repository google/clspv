; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[ptr:%[^ ]+]] = phi ptr addrspace(1) [ {{.*}} ], [ [[add_ptr:%[^ ]+]],
; CHECK: [[add_ptr]] = getelementptr <4 x half>, ptr addrspace(1) [[ptr]], i32 32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, <3 x i32>, %1 }
%1 = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @main_function(ptr addrspace(1) nocapture readnone align 8 %dst_tensor_buffer, ptr addrspace(1) nocapture readonly align 8 %src_tensor_buffer, ptr addrspace(1) nocapture readonly align 8 %weights_buffer, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %biases_image2d) local_unnamed_addr #0 !kernel_arg_addr_space !10 !kernel_arg_access_qual !11 !kernel_arg_type !12 !kernel_arg_base_type !13 !kernel_arg_type_qual !14 !reqd_work_group_size !15 !kernel_arg_name !16 !clspv.pod_args_impl !17 !kernel_arg_map !18 {
entry:
  %0 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 1), align 4
  %1 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 3), align 4
  %2 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 4), align 16
  %3 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 5), align 4
  %4 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 6), align 8
  %5 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 7), align 4
  %6 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 8), align 16
  %7 = load i32, ptr addrspace(9) getelementptr (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0), align 16
  %8 = load i32, ptr addrspace(5) getelementptr inbounds (<3 x i32>, ptr addrspace(5) @__spirv_WorkgroupId, i32 0, i32 1), align 4
  %9 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  %10 = add i32 %9, %8
  %mul.i = shl nsw i32 %10, 3
  %cmp.i.not = icmp slt i32 %mul.i, %0
  br i1 %cmp.i.not, label %if.end.i, label %main_function.inner.exit

if.end.i:                                         ; preds = %entry
  %call4.i = tail call spir_func i32 @_Z22get_sub_group_local_idv() #2
  %mul9.i = shl i32 %3, 5
  %mul10.i = mul i32 %mul9.i, %10
  %add.ptr.i = getelementptr inbounds <4 x half>, ptr addrspace(1) %weights_buffer, i32 %mul10.i
  br label %do.body.i

do.body.i:                                        ; preds = %do.body.i, %if.end.i
  %filters_loc.0.i = phi ptr addrspace(1) [ %add.ptr.i, %if.end.i ], [ %add.ptr32.i, %do.body.i ]
  %s.0.i = phi i32 [ 0, %if.end.i ], [ %add19.i, %do.body.i ]
  %arrayidx.i = getelementptr inbounds <4 x half>, ptr addrspace(1) %filters_loc.0.i, i32 %call4.i
  %11 = load <4 x half>, ptr addrspace(1) %arrayidx.i, align 8
  %add19.i = add nuw nsw i32 %s.0.i, 1
  %12 = extractelement <4 x half> %11, i64 0
  %call20.i = tail call spir_func half @_Z19sub_group_broadcastDhj(half %12, i32 0) #2
  %13 = extractelement <4 x half> %11, i64 1
  %call23.i = tail call spir_func half @_Z19sub_group_broadcastDhj(half %13, i32 0) #2
  %14 = extractelement <4 x half> %11, i64 2
  %call26.i = tail call spir_func half @_Z19sub_group_broadcastDhj(half %14, i32 0) #2
  %15 = extractelement <4 x half> %11, i64 3
  %call29.i = tail call spir_func half @_Z19sub_group_broadcastDhj(half %15, i32 0) #2
  %add.ptr32.i = getelementptr inbounds i8, ptr addrspace(1) %filters_loc.0.i, i32 256
  %cmp33.i = icmp slt i32 %add19.i, %3
  br i1 %cmp33.i, label %do.body.i, label %main_function.inner.exit

main_function.inner.exit:                         ; preds = %do.body.i, %entry
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !26 spir_func i32 @_Z22get_sub_group_local_idv() local_unnamed_addr #1

; Function Attrs: convergent nounwind
declare !kernel_arg_name !27 spir_func half @_Z19sub_group_broadcastDhj(half, i32) local_unnamed_addr #1

attributes #0 = { convergent norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !7, !7, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8, !8}
!_Z28clspv.entry_point_attributes = !{!9}

!0 = !{i32 1, i32 4, i32 6, i32 7}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 2, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 19.0.0git (git@github.com:rjodinchr/llvm-project.git f7a5e93e0da8464ff88a08a29ac60fd2587195d9)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!8 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!9 = !{!"main_function", !" __attribute__((reqd_work_group_size(64, 1, 1))) __attribute__((intel_reqd_sub_group_size(32))) __kernel"}
!10 = !{i32 1, i32 1, i32 1, i32 1, i32 0, i32 0, i32 0}
!11 = !{!"none", !"none", !"none", !"read_only", !"none", !"none", !"none"}
!12 = !{!"half4*", !"half4*", !"half4*", !"image2d_t", !"int4", !"int4", !"int4"}
!13 = !{!"half __attribute__((ext_vector_type(4)))*", !"half __attribute__((ext_vector_type(4)))*", !"half __attribute__((ext_vector_type(4)))*", !"image2d_t", !"int __attribute__((ext_vector_type(4)))", !"int __attribute__((ext_vector_type(4)))", !"int __attribute__((ext_vector_type(4)))"}
!14 = !{!"", !"", !"", !"", !"", !"", !""}
!15 = !{i32 64, i32 1, i32 1}
!16 = !{!"dst_tensor_buffer", !"src_tensor_buffer", !"weights_buffer", !"biases_image2d", !"shared_int4_0", !"shared_int4_1", !"shared_int4_2"}
!17 = !{i32 3}
!18 = !{!19, !20, !21, !22, !23, !24, !25}
!19 = !{!"dst_tensor_buffer", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!20 = !{!"src_tensor_buffer", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!21 = !{!"weights_buffer", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!22 = !{!"biases_image2d", i32 3, i32 3, i32 0, i32 0, !"ro_image"}
!23 = !{!"shared_int4_0", i32 4, i32 -1, i32 48, i32 16, !"pod_pushconstant"}
!24 = !{!"shared_int4_1", i32 5, i32 -1, i32 64, i32 16, !"pod_pushconstant"}
!25 = !{!"shared_int4_2", i32 6, i32 -1, i32 80, i32 16, !"pod_pushconstant"}
!26 = !{}
!27 = !{!"", !""}
