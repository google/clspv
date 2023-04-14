; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

; CHECK: [[outer:%[a-zA-Z0-9_.]+]] = type { <3 x i32>, <3 x i32>, [[inner:%[a-zA-Z0-9_.]+]] }
; @longs and @doubles need 24 i32s.
; CHECK: [[inner]] = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @chars(<2 x i8> %v2, <3 x i8> %v3, <4 x i8> %v4, <8 x i8> %v8, <16 x i8> %v16) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @chars() !clspv.pod_args_impl !1 !kernel_arg_map [[char_args:![0-9]+]]

  ; <2 x i8>
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <4 x i8>
  ; CHECK: shufflevector <4 x i8> [[cast]], <4 x i8> poison, <2 x i32> <i32 0, i32 1>

  ; <3 x i8>
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld]] to <4 x i8>
  ; CHECK: shufflevector <4 x i8> [[cast]], <4 x i8> poison, <3 x i32> <i32 0, i32 1, i32 2>

  ; <4 x i8>
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
  ; CHECK: bitcast i32 [[ld]] to <4 x i8>

  ; <8 x i8>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <4 x i8>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <4 x i8>
  ; CHECK: shufflevector <4 x i8> [[cast1]], <4 x i8> [[cast2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  ; <16 x 18>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <4 x i8>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <4 x i8>
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <4 x i8>
  ; CHECK: [[cast4:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld4]] to <4 x i8>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i8> [[cast1]], <4 x i8> [[cast2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: [[shuffle2:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i8> [[cast3]], <4 x i8> [[cast4]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: shufflevector <8 x i8> [[shuffle1]], <8 x i8> [[shuffle2]], <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  ret void
}

define spir_kernel void @shorts(<2 x i16> %v2, <3 x i16> %v3, <4 x i16> %v4, <8 x i16> %v8, <16 x i16> %v16) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @shorts() !clspv.pod_args_impl !1 !kernel_arg_map [[short_args:![0-9]+]]

  ; <2 x i16>
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: bitcast i32 [[ld]] to <2 x i16>

  ; <3 x i16>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 3), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x i16>
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: shufflevector <2 x i16> [[cast0]], <2 x i16> [[cast1]], <3 x i32> <i32 0, i32 1, i32 2>

  ; <4 x i16>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x i16>
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: shufflevector <2 x i16> [[cast0]], <2 x i16> [[cast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

  ; <8 x i16>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x i16>
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x i16>
  ; CHECK: [[cast4:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld4]] to <2 x i16>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast1]], <2 x i16> [[cast2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle2:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast3]], <2 x i16> [[cast4]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: shufflevector <4 x i16> [[shuffle1]], <4 x i16> [[shuffle2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  ; <16 x i16>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 16), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 17), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 18), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 19), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 20), align 4
  ; CHECK: [[ld6:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 21), align 4
  ; CHECK: [[ld7:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 22), align 4
  ; CHECK: [[ld8:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 23), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x i16>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x i16>
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x i16>
  ; CHECK: [[cast4:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld4]] to <2 x i16>
  ; CHECK: [[cast5:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld5]] to <2 x i16>
  ; CHECK: [[cast6:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld6]] to <2 x i16>
  ; CHECK: [[cast7:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld7]] to <2 x i16>
  ; CHECK: [[cast8:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld8]] to <2 x i16>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast1]], <2 x i16> [[cast2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle2:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast3]], <2 x i16> [[cast4]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle3:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast5]], <2 x i16> [[cast6]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle4:%[a-zA-Z0-9_.]+]] = shufflevector <2 x i16> [[cast7]], <2 x i16> [[cast8]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle5:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i16> [[shuffle1]], <4 x i16> [[shuffle2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: [[shuffle6:%[a-zA-Z0-9_.]+]] = shufflevector <4 x i16> [[shuffle3]], <4 x i16> [[shuffle4]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: shufflevector <8 x i16> [[shuffle5]], <8 x i16> [[shuffle6]], <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  ret void
}

define spir_kernel void @ints(<2 x i32> %v2, <3 x i32> %v3, <4 x i32> %v4) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @ints() !clspv.pod_args_impl !1 !kernel_arg_map [[int_args:![0-9]+]]

  ; <2 x i32>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> poison, i32 [[ld0]], i64 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[ld1]], i64 1
  
  ; <3 x i32>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 6), align 4
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <3 x i32> poison, i32 [[ld0]], i64 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <3 x i32> [[in0]], i32 [[ld1]], i64 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <3 x i32> [[in1]], i32 [[ld2]], i64 2
  
  ; <4 x i32>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x i32> poison, i32 [[ld0]], i64 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x i32> [[in0]], i32 [[ld1]], i64 1
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x i32> [[in1]], i32 [[ld2]], i64 2
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x i32> [[in2]], i32 [[ld3]], i64 3
  ret void
}

define spir_kernel void @longs(<2 x i64> %v2, <3 x i64> %v3, <4 x i64> %v4) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @longs() !clspv.pod_args_impl !1 !kernel_arg_map [[long_args:![0-9]+]]

  ; <2 x i64>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 3), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i64> poison, i64 [[or1]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i64> [[in0]], i64 [[or3]], i64 1

  ; <3 x i64>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 12), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 13), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <3 x i64> poison, i64 [[or1]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <3 x i64> [[in0]], i64 [[or3]], i64 1
  ; CHECK: [[zext4:%[a-zA-Z0-9_.]+]] = zext i32 [[ld4]] to i64
  ; CHECK: [[zext5:%[a-zA-Z0-9_.]+]] = zext i32 [[ld5]] to i64
  ; CHECK: [[shl5:%[a-zA-Z0-9_.]+]] = shl i64 [[zext5]], 32
  ; CHECK: [[or5:%[a-zA-Z0-9_.]+]] = or i64 [[zext4]], [[shl5]]
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <3 x i64> [[in1]], i64 [[or5]], i64 2

  ; <4 x i64>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 16), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 17), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 18), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 19), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 20), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 21), align 4
  ; CHECK: [[ld6:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 22), align 4
  ; CHECK: [[ld7:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 23), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> poison, i64 [[or1]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in0]], i64 [[or3]], i64 1
  ; CHECK: [[zext4:%[a-zA-Z0-9_.]+]] = zext i32 [[ld4]] to i64
  ; CHECK: [[zext5:%[a-zA-Z0-9_.]+]] = zext i32 [[ld5]] to i64
  ; CHECK: [[shl5:%[a-zA-Z0-9_.]+]] = shl i64 [[zext5]], 32
  ; CHECK: [[or5:%[a-zA-Z0-9_.]+]] = or i64 [[zext4]], [[shl5]]
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in1]], i64 [[or5]], i64 2
  ; CHECK: [[zext6:%[a-zA-Z0-9_.]+]] = zext i32 [[ld6]] to i64
  ; CHECK: [[zext7:%[a-zA-Z0-9_.]+]] = zext i32 [[ld7]] to i64
  ; CHECK: [[shl7:%[a-zA-Z0-9_.]+]] = shl i64 [[zext7]], 32
  ; CHECK: [[or7:%[a-zA-Z0-9_.]+]] = or i64 [[zext6]], [[shl7]]
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x i64> [[in2]], i64 [[or7]], i64 3
  ret void
}

define spir_kernel void @halfs(<2 x half> %v2, <3 x half> %v3, <4 x half> %v4, <8 x half> %v8, <16 x half> %v16) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @halfs() !clspv.pod_args_impl !1 !kernel_arg_map [[short_args]]

  ; <2 x half>
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: bitcast i32 [[ld]] to <2 x half>

  ; <3 x half>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 3), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x half>
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: shufflevector <2 x half> [[cast0]], <2 x half> [[cast1]], <3 x i32> <i32 0, i32 1, i32 2>

  ; <4 x half>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to <2 x half>
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: shufflevector <2 x half> [[cast0]], <2 x half> [[cast1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>

  ; <8 x half>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x half>
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x half>
  ; CHECK: [[cast4:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld4]] to <2 x half>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast1]], <2 x half> [[cast2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle2:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast3]], <2 x half> [[cast4]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: shufflevector <4 x half> [[shuffle1]], <4 x half> [[shuffle2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  ; <16 x half>
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 16), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 17), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 18), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 19), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 20), align 4
  ; CHECK: [[ld6:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 21), align 4
  ; CHECK: [[ld7:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 22), align 4
  ; CHECK: [[ld8:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 23), align 4
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to <2 x half>
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to <2 x half>
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to <2 x half>
  ; CHECK: [[cast4:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld4]] to <2 x half>
  ; CHECK: [[cast5:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld5]] to <2 x half>
  ; CHECK: [[cast6:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld6]] to <2 x half>
  ; CHECK: [[cast7:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld7]] to <2 x half>
  ; CHECK: [[cast8:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld8]] to <2 x half>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast1]], <2 x half> [[cast2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle2:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast3]], <2 x half> [[cast4]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle3:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast5]], <2 x half> [[cast6]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle4:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[cast7]], <2 x half> [[cast8]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ; CHECK: [[shuffle5:%[a-zA-Z0-9_.]+]] = shufflevector <4 x half> [[shuffle1]], <4 x half> [[shuffle2]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: [[shuffle6:%[a-zA-Z0-9_.]+]] = shufflevector <4 x half> [[shuffle3]], <4 x half> [[shuffle4]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ; CHECK: shufflevector <8 x half> [[shuffle5]], <8 x half> [[shuffle6]], <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  ret void
}

define spir_kernel void @floats(<2 x float> %v2, <3 x float> %v3, <4 x float> %v4) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @floats() !clspv.pod_args_impl !1 !kernel_arg_map [[int_args]]

  ; <2 x float>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to float
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> poison, float [[cast0]], i64 0
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to float
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> [[in0]], float [[cast1]], i64 1
  
  ; <3 x float>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 4), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 5), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 6), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to float
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <3 x float> poison, float [[cast0]], i64 0
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to float
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <3 x float> [[in0]], float [[cast1]], i64 1
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to float
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <3 x float> [[in1]], float [[cast2]], i64 2
  
  ; <4 x float>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld0]] to float
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> poison, float [[cast0]], i64 0
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld1]] to float
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in0]], float [[cast1]], i64 1
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld2]] to float
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in1]], float [[cast2]], i64 2
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ld3]] to float
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[in2]], float [[cast3]], i64 3
  ret void
}

define spir_kernel void @doubles(<2 x double> %v2, <3 x double> %v3, <4 x double> %v4) !clspv.pod_args_impl !1 {
entry:
  ; CHECK: define spir_kernel void @doubles() !clspv.pod_args_impl !1 !kernel_arg_map [[long_args]]

  ; <2 x double>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 2), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 3), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or1]] to double
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x double> poison, double [[cast0]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or3]] to double
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x double> [[in0]], double [[cast1]], i64 1

  ; <3 x double>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 8), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 9), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 10), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 11), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 12), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 13), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or1]] to double
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <3 x double> poison, double [[cast0]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or3]] to double
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <3 x double> [[in0]], double [[cast1]], i64 1
  ; CHECK: [[zext4:%[a-zA-Z0-9_.]+]] = zext i32 [[ld4]] to i64
  ; CHECK: [[zext5:%[a-zA-Z0-9_.]+]] = zext i32 [[ld5]] to i64
  ; CHECK: [[shl5:%[a-zA-Z0-9_.]+]] = shl i64 [[zext5]], 32
  ; CHECK: [[or5:%[a-zA-Z0-9_.]+]] = or i64 [[zext4]], [[shl5]]
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or5]] to double
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <3 x double> [[in1]], double [[cast2]], i64 2

  ; <4 x double>
  ; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 16), align 4
  ; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 17), align 4
  ; CHECK: [[ld2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 18), align 4
  ; CHECK: [[ld3:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 19), align 4
  ; CHECK: [[ld4:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 20), align 4
  ; CHECK: [[ld5:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 21), align 4
  ; CHECK: [[ld6:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 22), align 4
  ; CHECK: [[ld7:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(9) getelementptr inbounds ([[outer]], ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 23), align 4
  ; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ld0]] to i64
  ; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ld1]] to i64
  ; CHECK: [[shl1:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
  ; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl1]]
  ; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or1]] to double
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x double> poison, double [[cast0]], i64 0
  ; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i32 [[ld2]] to i64
  ; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i32 [[ld3]] to i64
  ; CHECK: [[shl3:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 32
  ; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[zext2]], [[shl3]]
  ; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or3]] to double
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <4 x double> [[in0]], double [[cast1]], i64 1
  ; CHECK: [[zext4:%[a-zA-Z0-9_.]+]] = zext i32 [[ld4]] to i64
  ; CHECK: [[zext5:%[a-zA-Z0-9_.]+]] = zext i32 [[ld5]] to i64
  ; CHECK: [[shl5:%[a-zA-Z0-9_.]+]] = shl i64 [[zext5]], 32
  ; CHECK: [[or5:%[a-zA-Z0-9_.]+]] = or i64 [[zext4]], [[shl5]]
  ; CHECK: [[cast2:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or5]] to double
  ; CHECK: [[in2:%[a-zA-Z0-9_.]+]] = insertelement <4 x double> [[in1]], double [[cast2]], i64 2
  ; CHECK: [[zext6:%[a-zA-Z0-9_.]+]] = zext i32 [[ld6]] to i64
  ; CHECK: [[zext7:%[a-zA-Z0-9_.]+]] = zext i32 [[ld7]] to i64
  ; CHECK: [[shl7:%[a-zA-Z0-9_.]+]] = shl i64 [[zext7]], 32
  ; CHECK: [[or7:%[a-zA-Z0-9_.]+]] = or i64 [[zext6]], [[shl7]]
  ; CHECK: [[cast3:%[a-zA-Z0-9_.]+]] = bitcast i64 [[or7]] to double
  ; CHECK: [[in3:%[a-zA-Z0-9_.]+]] = insertelement <4 x double> [[in2]], double [[cast3]], i64 3
  ret void
}

; CHECK: [[char_args]] = !{[[v2:![0-9]+]], [[v3:![0-9]+]], [[v4:![0-9]+]], [[v8:![0-9]+]], [[v16:![0-9]+]]}
; CHECK: [[v2]] = !{!"v2", i32 0, i32 -1, i32 32, i32 2, !"pod_pushconstant"}
; CHECK: [[v3]] = !{!"v3", i32 1, i32 -1, i32 36, i32 3, !"pod_pushconstant"}
; CHECK: [[v4]] = !{!"v4", i32 2, i32 -1, i32 40, i32 4, !"pod_pushconstant"}
; CHECK: [[v8]] = !{!"v8", i32 3, i32 -1, i32 48, i32 8, !"pod_pushconstant"}
; CHECK: [[v16]] = !{!"v16", i32 4, i32 -1, i32 64, i32 16, !"pod_pushconstant"}
; CHECK: [[short_args]] = !{[[v2:![0-9]+]], [[v3:![0-9]+]], [[v4:![0-9]+]], [[v8:![0-9]+]], [[v16:![0-9]+]]}
; CHECK: [[v2]] = !{!"v2", i32 0, i32 -1, i32 32, i32 4, !"pod_pushconstant"}
; CHECK: [[v3]] = !{!"v3", i32 1, i32 -1, i32 40, i32 6, !"pod_pushconstant"}
; CHECK: [[v4]] = !{!"v4", i32 2, i32 -1, i32 48, i32 8, !"pod_pushconstant"}
; CHECK: [[v8]] = !{!"v8", i32 3, i32 -1, i32 64, i32 16, !"pod_pushconstant"}
; CHECK: [[v16]] = !{!"v16", i32 4, i32 -1, i32 96, i32 32, !"pod_pushconstant"}
; CHECK: [[int_args]] = !{[[v2:![0-9]+]], [[v3:![0-9]+]], [[v4:![0-9]+]]}
; CHECK: [[v2]] = !{!"v2", i32 0, i32 -1, i32 32, i32 8, !"pod_pushconstant"}
; CHECK: [[v3]] = !{!"v3", i32 1, i32 -1, i32 48, i32 12, !"pod_pushconstant"}
; CHECK: [[v4]] = !{!"v4", i32 2, i32 -1, i32 64, i32 16, !"pod_pushconstant"}
; CHECK: [[long_args]] = !{[[v2:![0-9]+]], [[v3:![0-9]+]], [[v4:![0-9]+]]}
; CHECK: [[v2]] = !{!"v2", i32 0, i32 -1, i32 32, i32 16, !"pod_pushconstant"}
; CHECK: [[v3]] = !{!"v3", i32 1, i32 -1, i32 64, i32 24, !"pod_pushconstant"}
; CHECK: [[v4]] = !{!"v4", i32 2, i32 -1, i32 96, i32 32, !"pod_pushconstant"}

!0 = !{i32 1, i32 4}
!1 = !{i32 3}

