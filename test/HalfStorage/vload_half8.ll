; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <8 x float> @foo(half addrspace(1)* %a, i32 %b) {
entry:
  %0 = call spir_func <8 x float> @_Z11vload_half8jPU3AS1KDh(i32 %b, half addrspace(1)* %a)
  ret <8 x float> %0
}

declare spir_func <8 x float> @_Z11vload_half8jPU3AS1KDh(i32, half addrspace(1)*)

; CHECK:  [[a4i32:%[^ ]+]] = bitcast half addrspace(1)* %a to <4 x i32> addrspace(1)*
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x i32>, <4 x i32> addrspace(1)* [[a4i32]], i32 %b
; CHECK:  [[vali32:%[^ ]+]] = load <4 x i32>, <4 x i32> addrspace(1)* [[gep]], align 16
; CHECK:  [[val01i32:%[^ ]+]] = extractelement <4 x i32> [[vali32]], i32 0
; CHECK:  [[val23i32:%[^ ]+]] = extractelement <4 x i32> [[vali32]], i32 1
; CHECK:  [[val45i32:%[^ ]+]] = extractelement <4 x i32> [[vali32]], i32 2
; CHECK:  [[val67i32:%[^ ]+]] = extractelement <4 x i32> [[vali32]], i32 3
; CHECK:  [[val01:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val01i32]])
; CHECK:  [[val23:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val23i32]])
; CHECK:  [[val45:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val45i32]])
; CHECK:  [[val67:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val67i32]])
; CHECK:  [[ret0123:%[^ ]+]] = shufflevector <2 x float> [[val01]], <2 x float> [[val23]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret4567:%[^ ]+]] = shufflevector <2 x float> [[val45]], <2 x float> [[val67]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret:%[^ ]+]] = shufflevector <4 x float> [[ret0123]], <4 x float> [[ret4567]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
