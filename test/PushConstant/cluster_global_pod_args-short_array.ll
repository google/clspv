; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%original = type { i8, [8 x i16] }

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { [[inner:%[a-zA-Z0-9_.]+]] }
; CHECK: [[inner]] = type { i32, i32, i32, i32, i32 }

; CHECK: @__push_constants = addrspace(9) global [[outer]] zeroinitializer, !push_constants [[pc_md:![0-9]+]]

define spir_kernel void @i8x16(%original %arg) !clspv.pod_args_impl !0 {
entry:
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) @__push_constants, align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 3), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 0, i32 4), align 4

  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld0]] to i8
  ; CHECK: [[s_in0:%[a-zA-Z0-9_.]+]] = insertvalue %original poison, i8 [[cast]], 0

  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] poison, i16 [[ex]], 0
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld1]] to i16
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in0]], i16 [[cast]], 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in1]], i16 [[ex]], 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld2]] to i16
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in2]], i16 [[cast]], 3
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in3]], i16 [[ex]], 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld3]] to i16
  ; CHECK: [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in4]], i16 [[cast]], 5
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x i16>
  ; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractelement <2 x i16> [[cast]], i64 1
  ; CHECK: [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in5]], i16 [[ex]], 6
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = trunc i32 [[ld4]] to i16
  ; CHECK: [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i16] [[in6]], i16 [[cast]], 7
  ; CHECK: [[s_in1:%[a-zA-Z0-9_.]+]] = insertvalue %original [[s_in0]], [8 x i16] [[in7]], 1
  ret void
}

!0 = !{i32 3}
