; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x float> @foo(ptr addrspace(1) %a, i32 %b) {
entry:
  %0 = call spir_func <3 x float> @_Z11vload_half3jPU3AS1KDh(i32 %b, ptr addrspace(1) %a)
  ret <3 x float> %0
}

declare spir_func <3 x float> @_Z11vload_half3jPU3AS1KDh(i32, ptr addrspace(1))

; CHECK:  [[bx2:%[^ ]+]] = shl i32 %b, 1
; CHECK:  [[idx0:%[^ ]+]] = add i32 [[bx2]], %b
; CHECK:  [[gep0:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[idx0]]
; CHECK:  [[val0i16:%[^ ]+]] = load i16, ptr addrspace(1) [[gep0]], align 2
; CHECK:  [[val0i32:%[^ ]+]] = zext i16 [[val0i16]] to i32
; CHECK:  [[val2f0:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val0i32]])
; CHECK:  [[val0:%[^ ]+]] = extractelement <2 x float> [[val2f0]], i32 0

; CHECK:  [[idx1:%[^ ]+]] = add i32 [[idx0]], 1
; CHECK:  [[gep1:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[idx1]]
; CHECK:  [[val1i16:%[^ ]+]] = load i16, ptr addrspace(1) [[gep1]], align 2
; CHECK:  [[val1i32:%[^ ]+]] = zext i16 [[val1i16]] to i32
; CHECK:  [[val2f1:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val1i32]])
; CHECK:  [[val1:%[^ ]+]] = extractelement <2 x float> [[val2f1]], i32 0

; CHECK:  [[idx2:%[^ ]+]] = add i32 [[idx1]], 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr i16, ptr addrspace(1) %a, i32 [[idx2]]
; CHECK:  [[val2i16:%[^ ]+]] = load i16, ptr addrspace(1) [[gep2]], align 2
; CHECK:  [[val2i32:%[^ ]+]] = zext i16 [[val2i16]] to i32
; CHECK:  [[val2f2:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val2i32]])
; CHECK:  [[val2:%[^ ]+]] = extractelement <2 x float> [[val2f2]], i32 0

; CHECK:  [[ret0:%[^ ]+]] = insertelement <3 x float> poison, float [[val0]], i32 0
; CHECK:  [[ret01:%[^ ]+]] = insertelement <3 x float> [[ret0]], float [[val1]], i32 1
; CHECK:  [[ret:%[^ ]+]] = insertelement <3 x float> [[ret01]], float [[val2]], i32 2
