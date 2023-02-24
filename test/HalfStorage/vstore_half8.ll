; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %a, <8 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z12vstore_half8Dv8_fjPU3AS1Dh(<8 x float> %b, i32 %c, ptr addrspace(1) %a)
  ret void
}

declare spir_func void @_Z12vstore_half8Dv8_fjPU3AS1Dh(<8 x float>, i32, ptr addrspace(1))

; CHECK:  [[b01:%[^ ]+]] = shufflevector <8 x float> %b, <8 x float> poison, <2 x i32> <i32 0, i32 1>
; CHECK:  [[b23:%[^ ]+]] = shufflevector <8 x float> %b, <8 x float> poison, <2 x i32> <i32 2, i32 3>
; CHECK:  [[b45:%[^ ]+]] = shufflevector <8 x float> %b, <8 x float> poison, <2 x i32> <i32 4, i32 5>
; CHECK:  [[b67:%[^ ]+]] = shufflevector <8 x float> %b, <8 x float> poison, <2 x i32> <i32 6, i32 7>
; CHECK:  [[b01i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b01]])
; CHECK:  [[b23i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b23]])
; CHECK:  [[b45i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b45]])
; CHECK:  [[b67i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b67]])
; CHECK:  [[bv0:%[^ ]+]] = insertelement <4 x i32> poison, i32 [[b01i32]], i32 0
; CHECK:  [[bv1:%[^ ]+]] = insertelement <4 x i32> [[bv0]], i32 [[b23i32]], i32 1
; CHECK:  [[bv2:%[^ ]+]] = insertelement <4 x i32> [[bv1]], i32 [[b45i32]], i32 2
; CHECK:  [[bv3:%[^ ]+]] = insertelement <4 x i32> [[bv2]], i32 [[b67i32]], i32 3
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 %c
; CHECK:  store <4 x i32> [[bv3]], ptr addrspace(1) [[gep]], align 16
