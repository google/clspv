; TODO(#816): remove opaque pointers disable
; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass -opaque-pointers=0
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { i8 }
%1 = type { %0, %0, %0, %0 }
%2 = type { i8, i64 }
%3 = type { i8, %2 }

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner:%[a-zA-Z0-9_.]+]] = type { i32, i32, i32, i32, i32, i32 }
; CHECK-DAG: [[s0:%[a-zA-Z0-9_.]+]] = type { i8 }
; CHECK-DAG: [[s1:%[a-zA-Z0-9_.]+]] = type { [[s0]], [[s0]], [[s0]], [[s0]] }
; CHECK-DAG: [[s2:%[a-zA-Z0-9_.]+]] = type { i8, i64 }
; CHECK-DAG: [[s3:%[a-zA-Z0-9_.]+]] = type { i8, [[s2]] }

; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

define spir_kernel void @chars(%1 %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @chars() !clspv.pod_args_impl [[pod_arg_md:![0-9]+]] !kernel_arg_map [[chars_map:![0-9]+]]

  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld]] to i8
  ; CHECK: [[in:%[a-zA-Z0-9_.]+]] = insertvalue [[s0]] poison, i8 [[cast]], 0
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [[s1]] poison, %3 [[in]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 1
  ; CHECK: [[in:%[a-zA-Z0-9_.]+]] = insertvalue [[s0]] poison, i8 [[ex]], 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [[s1]] [[in0]], %3 [[in]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 2
  ; CHECK: [[in:%[a-zA-Z0-9_.]+]] = insertvalue [[s0]] poison, i8 [[ex]], 0
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [[s1]] [[in1]], %3 [[in]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 3
  ; CHECK: [[in:%[a-zA-Z0-9_.]+]] = insertvalue [[s0]] poison, i8 [[ex]], 0
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [[s1]] [[in2]], %3 [[in]], 3
  ret void
}

define spir_kernel void @aligns(%3 %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @aligns() !clspv.pod_args_impl [[pod_arg_md]] !kernel_arg_map [[aligns_map:![0-9]+]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 4), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 5), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld0]] to i8
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [[s3]] poison, i8 [[cast]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld2]] to i8
  ; CHECK: [[in00:%[a-zA-Z0-9_.]+]] = insertvalue [[s2]] poison, i8 [[cast]], 0
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld4]] to i64
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld5]] to i64
  ; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[ex1]], 32
  ; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[ex0]], [[shl]]
  ; CHECK: [[in01:%[a-zA-Z0-9_.]+]] = insertvalue [[s2]] [[in00]], i64 [[or]], 1
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [[s3]] [[in0]], [[s2]] [[in01]], 1
  ret void
}

; CHECK: [[pc_md]] = !{i32 7}
; CHECK: [[pod_arg_md]] = !{i32 3}
; CHECK: [[chars_map]] = !{[[arg_md:![0-9]+]]}
; CHECK: [[arg_md]] = !{!"arg", i32 0, i32 -1, i32 0, i32 4, !"pod_pushconstant"}
; CHECK: [[aligns_map]] = !{[[arg_md:![0-9]+]]}
; CHECK: [[arg_md]] = !{!"arg", i32 0, i32 -1, i32 0, i32 24, !"pod_pushconstant"}

!0 = !{i32 3}
