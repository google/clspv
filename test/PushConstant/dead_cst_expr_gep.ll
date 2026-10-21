; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { <3 x i32>, <3 x i32>, [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32 }
; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out)
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr inbounds [[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) [[gep0]], align 4
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds nuw (i8, ptr addrspace(9) @__push_constants, i32 20), align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo(ptr addrspace(1) %out, i32 %int_arg) !clspv.pod_args_impl !1 {
entry:
  %0 = load i32, ptr addrspace(9) getelementptr inbounds (<3 x i32>, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), i32 0, i32 1), align 4
  %1 = add i32 %0, %int_arg
  store i32 %1, ptr addrspace(1) %out
  ret void
}

!0 = !{i32 1, i32 4}
!1 = !{i32 3}
