; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { <3 x i32>, <3 x i32>, [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32, i32, i32, i32, i32, i32, i32, i32 }
; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out) !clspv.pod_args_impl [[pod_args_md:![0-9]+]] !kernel_arg_map [[arg_map_md:![0-9]+]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
; CHECK: trunc i32 [[ld]] to i8

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <2 x i16>
; CHECK: extractelement <2 x i16> [[cast]], i64 1

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4

; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 3), align 4
; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
; CHECK: or i64 [[zext0]], [[shl]]

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
; CHECK: bitcast i32 [[ld]] to float

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <2 x half>
; CHECK: extractelement <2 x half> [[cast]], i64 0

; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 6), align 4
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 7), align 4
; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl]]
; CHECK: bitcast i64 [[or]] to double

; CHECK: [[pc_md]] = !{i32 1, i32 4, i32 7}
; CHECK: [[pod_args_md]] = !{i32 3}
; CHECK: [[arg_map_md]] = !{[[out_md:![0-9]+]], [[char_arg_md:![0-9]+]], [[short_arg_md:![0-9]+]], [[int_arg_md:![0-9]+]], [[long_arg_md:![0-9]+]], [[float_arg_md:![0-9]+]], [[half_arg_md:![0-9]+]], [[double_arg_md:![0-9]+]]}
; CHECK: [[out_md]] = !{!"out", i32 0, i32 0
; CHECK: [[char_arg_md]] = !{!"char_arg", i32 1, i32 -1, i32 32, i32 1, !"pod_pushconstant"}
; CHECK: [[short_arg_md]] = !{!"short_arg", i32 2, i32 -1, i32 34, i32 2, !"pod_pushconstant"}
; CHECK: [[int_arg_md]] = !{!"int_arg", i32 3, i32 -1, i32 36, i32 4, !"pod_pushconstant"}
; CHECK: [[long_arg_md]] = !{!"long_arg", i32 4, i32 -1, i32 40, i32 8, !"pod_pushconstant"}
; CHECK: [[float_arg_md]] = !{!"float_arg", i32 5, i32 -1, i32 48, i32 4, !"pod_pushconstant"}
; CHECK: [[half_arg_md]] = !{!"half_arg", i32 6, i32 -1, i32 52, i32 2, !"pod_pushconstant"}
; CHECK: [[double_arg_md]] = !{!"double_arg", i32 7, i32 -1, i32 56, i32 8, !"pod_pushconstant"}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo(ptr addrspace(1) %out, i8 %char_arg, i16 %short_arg, i32 %int_arg, i64 %long_arg, float %float_arg, half %half_arg, double %double_arg) !clspv.pod_args_impl !1 {
entry:
  store i32 %int_arg, ptr addrspace(1) %out
  ret void
}

!0 = !{i32 1, i32 4}
!1 = !{i32 3}

