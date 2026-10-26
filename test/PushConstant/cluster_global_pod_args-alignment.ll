; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { i64, [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32, i32, i32, i32 }
; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out) !clspv.pod_args_impl [[pod_args_md:![0-9]+]] !kernel_arg_map [[arg_map_md:![0-9]+]]
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr inbounds [[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0
; CHECK: load i32, ptr addrspace(9) [[gep0]], align 4

; CHECK-DAG: [[pc_md]] = !{i32 9, i32 7}
; CHECK-DAG: [[pod_args_md]] = !{i32 3}
; CHECK-DAG: [[arg_map_md]] = !{[[out_md:![0-9]+]], [[vec_arg_md:![0-9]+]]}
; CHECK-DAG: [[out_md]] = !{!"out", i32 0, i32 0
; CHECK-DAG: [[vec_arg_md]] = !{!"vec_arg", i32 1, i32 -1, i32 8, i32 16, !"pod_pushconstant"}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%0 = type { i64 }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo(ptr addrspace(1) %out, <4 x float> %vec_arg) !clspv.pod_args_impl !1 {
entry:
  store <4 x float> %vec_arg, ptr addrspace(1) %out
  ret void
}

!0 = !{i32 9}
!1 = !{i32 3}
