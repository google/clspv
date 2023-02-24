; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %a, <3 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z12vstore_half3Dv3_fjPU3AS1Dh(<3 x float> %b, i32 %c, ptr addrspace(1) %a)
  ret void
}

declare spir_func void @_Z12vstore_half3Dv3_fjPU3AS1Dh(<3 x float>, i32, ptr addrspace(1))


; CHECK:  [[b0:%[^ ]+]] = extractelement <3 x float> %b, i32 0
; CHECK:  [[b0f2:%[^ ]+]] = insertelement <2 x float> poison, float [[b0]], i32 0
; CHECK:  [[b1:%[^ ]+]] = extractelement <3 x float> %b, i32 1
; CHECK:  [[b1f2:%[^ ]+]] = insertelement <2 x float> poison, float [[b1]], i32 0
; CHECK:  [[b2:%[^ ]+]] = extractelement <3 x float> %b, i32 2
; CHECK:  [[b2f2:%[^ ]+]] = insertelement <2 x float> poison, float [[b2]], i32 0
; CHECK:  [[b0i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b0f2]])
; CHECK:  [[b0i16:%[^ ]+]] = trunc i32 [[b0i32]] to i16
; CHECK:  [[b1i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b1f2]])
; CHECK:  [[b1i16:%[^ ]+]] = trunc i32 [[b1i32]] to i16
; CHECK:  [[b2i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b2f2]])
; CHECK:  [[b2i16:%[^ ]+]] = trunc i32 [[b2i32]] to i16
; CHECK:  [[cx2:%[^ ]+]] = shl i32 %c, 1
; CHECK:  [[cx3:%[^ ]+]] = add i32 [[cx2]], %c
; CHECK:  [[gep0:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[cx3]]
; CHECK:  store i16 [[b0i16]], ptr addrspace(1) [[gep0]], align 2
; CHECK:  [[idx1:%[^ ]+]] = add i32 [[cx3]], 1
; CHECK:  [[gep1:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[idx1]]
; CHECK:  store i16 [[b1i16]], ptr addrspace(1) [[gep1]], align 2
; CHECK:  [[idx2:%[^ ]+]] = add i32 [[idx1]], 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[idx2]]
; CHECK:  store i16 [[b2i16]], ptr addrspace(1) [[gep2]], align 2
