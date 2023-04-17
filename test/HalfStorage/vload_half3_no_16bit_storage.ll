; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin --no-16bit-storage=ssbo
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x float> @foo(ptr addrspace(1) %a, i32 %b) {
entry:
  %0 = call spir_func <3 x float> @_Z11vload_half3jPU3AS1KDh(i32 %b, ptr addrspace(1) %a)
  ret <3 x float> %0
}

declare spir_func <3 x float> @_Z11vload_half3jPU3AS1KDh(i32, ptr addrspace(1))

; CHECK:  [[shl:%[^ ]+]] = shl i32 %b, 1
; CHECK:  [[add0:%[^ ]+]] = add i32 [[shl]], %b
; CHECK:  [[and:%[^ ]+]] = and i32 [[add0]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add0]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[unpack:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[load]])
; CHECK:  [[val0:%[^ ]+]] = extractelement <2 x float> [[unpack]], i32 [[and]]

; CHECK:  [[add1:%[^ ]+]] = add i32 [[add0]], 1
; CHECK:  [[and:%[^ ]+]] = and i32 [[add1]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add1]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[unpack:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[load]])
; CHECK:  [[val1:%[^ ]+]] = extractelement <2 x float> [[unpack]], i32 [[and]]

; CHECK:  [[add2:%[^ ]+]] = add i32 [[add1]], 1
; CHECK:  [[and:%[^ ]+]] = and i32 [[add2]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add2]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[unpack:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[load]])
; CHECK:  [[val2:%[^ ]+]] = extractelement <2 x float> [[unpack]], i32 [[and]]

; CHECK:  [[ret0:%[^ ]+]] = insertelement <3 x float> poison, float [[val0]], i32 0
; CHECK:  [[ret01:%[^ ]+]] = insertelement <3 x float> [[ret0]], float [[val1]], i32 1
; CHECK:  [[ret:%[^ ]+]] = insertelement <3 x float> [[ret01]], float [[val2]], i32 2
