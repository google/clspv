; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x float> @foo(half addrspace(1)* %a, i32 %b) {
entry:
  %0 = call spir_func <3 x float> @_Z12vloada_half3jPU3AS1KDh(i32 %b, half addrspace(1)* %a)
  ret <3 x float> %0
}

declare spir_func <3 x float> @_Z12vloada_half3jPU3AS1KDh(i32, half addrspace(1)*)

; CHECK:  [[a2i32:%[^ ]+]] = bitcast half addrspace(1)* %a to <2 x i32> addrspace(1)*
; CHECK:  [[gep:%[^ ]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* [[a2i32]], i32 %b
; CHECK:  [[vali32:%[^ ]+]] = load <2 x i32>, <2 x i32> addrspace(1)* [[gep]], align 8
; CHECK:  [[val01i32:%[^ ]+]] = extractelement <2 x i32> [[vali32]], i32 0
; CHECK:  [[val23i32:%[^ ]+]] = extractelement <2 x i32> [[vali32]], i32 1
; CHECK:  [[val01:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val01i32]])
; CHECK:  [[val23:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val23i32]])
; CHECK:  [[ret:%[^ ]+]] = shufflevector <2 x float> [[val01]], <2 x float> [[val23]], <3 x i32> <i32 0, i32 1, i32 2>
