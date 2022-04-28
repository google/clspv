; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define float @foo(half addrspace(1)* %a, i32 %b) {
entry:
  %0 = call spir_func float @_Z10vload_halfjPU3AS1KDh(i32 %b, half addrspace(1)* %a)
  ret float %0
}

declare spir_func float @_Z10vload_halfjPU3AS1KDh(i32, half addrspace(1)*)

; CHECK:  [[ai16:%[^ ]+]] = bitcast half addrspace(1)* %a to i16 addrspace(1)*
; CHECK:  [[gep:%[^ ]+]] = getelementptr i16, i16 addrspace(1)* [[ai16]], i32 %b
; CHECK:  [[reti16:%[^ ]+]] = load i16, i16 addrspace(1)* [[gep]], align 2
; CHECK:  [[reti32:%[^ ]+]] = zext i16 [[reti16]] to i32
; CHECK:  [[retf2:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[reti32]])
; CHECK:  [[ret:%[^ ]+]] = extractelement <2 x float> [[retf2]], i32 0
