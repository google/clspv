; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %a, <4 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z13vstore_half_4Dv4_fjPU3AS1Dh(<4 x float> %b, i32 %c, ptr addrspace(1) %a)
  ret void
}

declare spir_func void @_Z13vstore_half_4Dv4_fjPU3AS1Dh(<4 x float>, i32, ptr addrspace(1))

; CHECK:  [[b01:%[^ ]+]] = shufflevector <4 x float> %b, <4 x float> poison, <2 x i32> <i32 0, i32 1>
; CHECK:  [[b23:%[^ ]+]] = shufflevector <4 x float> %b, <4 x float> poison, <2 x i32> <i32 2, i32 3>
; CHECK:  [[b01i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b01]])
; CHECK:  [[b23i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b23]])
; CHECK:  [[b01v2i32:%[^ ]+]] = insertelement <2 x i32> poison, i32 [[b01i32]], i32 0
; CHECK:  [[b0123v2i32:%[^ ]+]] = insertelement <2 x i32> [[b01v2i32]], i32 [[b23i32]], i32 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, ptr addrspace(1) %a, i32 %c
; CHECK:  store <2 x i32> [[b0123v2i32]], ptr addrspace(1) [[gep]], align 8
