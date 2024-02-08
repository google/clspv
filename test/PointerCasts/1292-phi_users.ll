; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[ptr:%[^ ]+]] = phi ptr addrspace(1) [ {{.*}} ], [ [[add_ptr:%[^ ]+]],
; CHECK: [[add_ptr]] = getelementptr <4 x half>, ptr addrspace(1) [[ptr]], i32 32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, <3 x i32>, %1 }
%1 = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }

@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @main_function(ptr addrspace(1) nocapture readnone align 8 %dst_tensor_buffer, ptr addrspace(1) nocapture readonly align 8 %src_tensor_buffer, ptr addrspace(1) nocapture readonly align 8 %weights_buffer, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %biases_image2d) !clspv.pod_args_impl !17 !kernel_arg_map !18 {
entry:
  %0 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 3, i32 1), align 4
  %cmp.i.not = icmp slt i32 %0, 10
  br i1 %cmp.i.not, label %if.end.i, label %main_function.inner.exit

if.end.i:                                         ; preds = %entry
  %add.ptr.i = getelementptr inbounds <4 x half>, ptr addrspace(1) %weights_buffer, i32 0
  br label %do.body.i

do.body.i:                                        ; preds = %do.body.i, %if.end.i
  %filters_loc.0.i = phi ptr addrspace(1) [ %add.ptr.i, %if.end.i ], [ %add.ptr32.i, %do.body.i ]
  %s.0.i = phi i32 [ 0, %if.end.i ], [ %add19.i, %do.body.i ]
  %arrayidx.i = getelementptr inbounds <4 x half>, ptr addrspace(1) %filters_loc.0.i, i32 0
  %ld = load <4 x half>, ptr addrspace(1) %arrayidx.i, align 8
  %add.ptr32.i = getelementptr inbounds i8, ptr addrspace(1) %filters_loc.0.i, i32 256
  %add19.i = add i32 %s.0.i, 1
  %cmp33.i = icmp slt i32 %add19.i, 10
  br i1 %cmp33.i, label %do.body.i, label %main_function.inner.exit

main_function.inner.exit:                         ; preds = %do.body.i, %entry
  ret void
}

!0 = !{i32 1, i32 4, i32 6, i32 7}
!17 = !{i32 3}
!18 = !{!19, !20, !21, !22, !23, !24, !25}
!19 = !{!"dst_tensor_buffer", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!20 = !{!"src_tensor_buffer", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!21 = !{!"weights_buffer", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!22 = !{!"biases_image2d", i32 3, i32 3, i32 0, i32 0, !"ro_image"}
!23 = !{!"shared_int4_0", i32 4, i32 -1, i32 48, i32 16, !"pod_pushconstant"}
!24 = !{!"shared_int4_1", i32 5, i32 -1, i32 64, i32 16, !"pod_pushconstant"}
!25 = !{!"shared_int4_2", i32 6, i32 -1, i32 80, i32 16, !"pod_pushconstant"}
