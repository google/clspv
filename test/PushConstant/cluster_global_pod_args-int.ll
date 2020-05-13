; RUN: clspv-opt %s -o %t.ll -ClusterPodKernelArgumentsPass
; RUN: FileCheck %s < %t.ll

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { <3 x i32>, <3 x i32>, [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32 }
; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

; CHECK: define spir_kernel void @foo(i32 addrspace(1)* %out) !clspv.pod_args_impl [[pod_args_md:![0-9]+]] !kernel_arg_map [[arg_map_md:![0-9]+]]
; CHECK: load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 2, i32 0), align 4

; CHECK: [[pc_md]] = !{i32 1, i32 4, i32 7}
; CHECK: [[pod_args_md]] = !{i32 3}
; CHECK: [[arg_map_md]] = !{[[out_md:![0-9]+]], [[int_arg_md:![0-9]+]]}
; CHECK: [[out_md]] = !{!"out", i32 0, i32 0
; CHECK: [[int_arg_md]] = !{!"int_arg", i32 1, i32 -1, i32 32, i32 4, !"pod_pushconstant"}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo(i32 addrspace(1)* %out, i32 %int_arg) !clspv.pod_args_impl !1 {
entry:
  ret void
}

!0 = !{i32 1, i32 4}
!1 = !{i32 3}

