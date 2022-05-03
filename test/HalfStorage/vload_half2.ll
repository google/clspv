; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x float> @foo(half addrspace(1)* %a, i32 %b) {
entry:
  %0 = call spir_func <2 x float> @_Z11vload_half2jPU3AS1KDh(i32 %b, half addrspace(1)* %a)
  ret <2 x float> %0
}

declare spir_func <2 x float> @_Z11vload_half2jPU3AS1KDh(i32, half addrspace(1)*)

; CHECK:  [[ai32:%[^ ]+]] = bitcast half addrspace(1)* %a to i32 addrspace(1)*
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, i32 addrspace(1)* [[ai32]], i32 %b
; CHECK:  [[reti32:%[^ ]+]] = load i32, i32 addrspace(1)* [[gep]], align 4
; CHECK:  [[ret:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[reti32]])
