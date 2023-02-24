; TODO(#816): remove opaque pointers disable
; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass -opaque-pointers=0
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32, i32, i32, i32 }

; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

define spir_kernel void @i8x16([16 x i8] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @i8x16() !clspv.pod_args_impl [[pod_args_md:![0-9]+]] !kernel_arg_map [[map_md:![0-9]+]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld0]] to i8
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] poison, i8 [[cast]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 1
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in0]], i8 [[ex]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 2
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in1]], i8 [[ex]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 3
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in2]], i8 [[ex]], 3
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld1]] to i8
  ; CHECK: [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in3]], i8 [[cast]], 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 1
  ; CHECK: [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in4]], i8 [[ex]], 5
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 2
  ; CHECK: [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in5]], i8 [[ex]], 6
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 3
  ; CHECK: [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in6]], i8 [[ex]], 7
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld2]] to i8
  ; CHECK: [[in8:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in7]], i8 [[cast]], 8
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 1
  ; CHECK: [[in9:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in8]], i8 [[ex]], 9
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 2
  ; CHECK: [[in10:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in9]], i8 [[ex]], 10
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 3
  ; CHECK: [[in11:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in10]], i8 [[ex]], 11
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld3]] to i8
  ; CHECK: [[in12:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in11]], i8 [[cast]], 12
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 1
  ; CHECK: [[in13:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in12]], i8 [[ex]], 13
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 2
  ; CHECK: [[in14:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in13]], i8 [[ex]], 14
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <4 x i8>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast]], i64 3
  ; CHECK: [[in15:%[a-zA-Z0-9_.]+]] = insertvalue [16 x i8] [[in14]], i8 [[ex]], 15
  ret void
}

define spir_kernel void @i16x8([8 x i16] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @i16x8() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld0]] to i16
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] poison, i16 [[cast]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in0]], i16 [[ex]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld1]] to i16
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in1]], i16 [[cast]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in2]], i16 [[ex]], 3
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld2]] to i16
  ; CHECK: [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in3]], i16 [[cast]], 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in4]], i16 [[ex]], 5
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld3]] to i16
  ; CHECK: [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in5]], i16 [[cast]], 6
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in6]], i16 [[ex]], 7
  ret void
}

define spir_kernel void @i32x4([4 x i32] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @i32x4() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i32] poison, i32 [[ld0]], 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i32] [[in0]], i32 [[ld1]], 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i32] [[in1]], i32 [[ld2]], 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i32] [[in2]], i32 [[ld3]], 3
  ret void
}

define spir_kernel void @i64x2([2 x i64] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @i64x2() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[ex1]], 32
  ; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[ex0]], [[shl]]
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i64] poison, i64 [[or]], 0
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[ex1]], 32
  ; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[ex0]], [[shl]]
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i64] [[in0]], i64 [[or]], 1
  ret void
}

define spir_kernel void @halfx8([8 x half] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @halfx8() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 0
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] poison, half [[ex]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 1
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in0]], half [[ex]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 0
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in1]], half [[ex]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 1
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in2]], half [[ex]], 3
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 0
  ; CHECK: [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in3]], half [[ex]], 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 1
  ; CHECK: [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in4]], half [[ex]], 5
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 0
  ; CHECK: [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in5]], half [[ex]], 6
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x half>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x half> [[cast]], i64 1
  ; CHECK: [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [8 x half] [[in6]], half [[ex]], 7
  ret void
}

define spir_kernel void @floatx4([4 x float] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @floatx4() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to float
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [4 x float] poison, float [[cast]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to float
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [4 x float] [[in0]], float [[cast]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to float
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [4 x float] [[in1]], float [[cast]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to float
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [4 x float] [[in2]], float [[cast]], 3
  ret void
}

define spir_kernel void @doublex2([2 x double] %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: define spir_kernel void @doublex2() !clspv.pod_args_impl [[pod_args_md]] !kernel_arg_map [[map_md]]

  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(9)* getelementptr inbounds (%0, %0 addrspace(9)* @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[ex1]], 32
  ; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[ex0]], [[shl]]
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or]] to double
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [2 x double] poison, double [[cast]], 0
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[ex1]], 32
  ; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[ex0]], [[shl]]
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or]] to double
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [2 x double] [[in0]], double [[cast]], 1
  ret void
}

; CHECK: [[pc_md]] = !{i32 7}
; CHECK: [[pod_args_md]] = !{i32 3}
; CHECK: [[map_md]] = !{[[arg_md:![0-9]+]]}
; CHECK: [[arg_md]] = !{!"arg", i32 0, i32 -1, i32 0, i32 16, !"pod_pushconstant"}

!0 = !{i32 3}
