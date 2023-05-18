; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: [[pc_struct:%[^ ]+]] = type { <3 x i32>, [[pc_inner_struct:%[^ ]+]] }
; CHECK: [[pc_inner_struct]] = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }
; CHECK: [[pc:@[^ ]+]] = addrspace(9) global [[pc_struct]] zeroinitializer, !push_constants !0
; CHECK: load i32, ptr addrspace(9) getelementptr inbounds ([[pc_struct]], ptr addrspace(9) [[pc]], i32 0, i32 0, i32 2), align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define dso_local spir_kernel void @main_function(ptr addrspace(1) align 8 %dst_tensor_buffer, ptr addrspace(1) align 8 %src_tensor_buffer, <4 x i32> %shared_int4_0, <4 x i32> %shared_int4_1, <4 x float> %shared_float4_0) !kernel_arg_addr_space !6 !kernel_arg_access_qual !7 !kernel_arg_type !8 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = load i32, ptr addrspace(9) getelementptr inbounds ({ <3 x i32> }, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 2), align 4
  ret void
}

!0 = !{i32 6}
!6 = !{i32 1, i32 1, i32 0, i32 0, i32 0}
!7 = !{!"none", !"none", !"none", !"none", !"none"}
!8 = !{!"half4*", !"half4*", !"int4", !"int4", !"float4"}
!9 = !{!"half __attribute__((ext_vector_type(4)))*", !"half __attribute__((ext_vector_type(4)))*", !"int __attribute__((ext_vector_type(4)))", !"int __attribute__((ext_vector_type(4)))", !"float __attribute__((ext_vector_type(4)))"}
!10 = !{!"", !"", !"", !"", !""}
!11 = !{i32 3}
