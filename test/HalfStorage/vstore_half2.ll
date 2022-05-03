; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(half addrspace(1)* %a, <2 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z12vstore_half2Dv2_fjPU3AS1Dh(<2 x float> %b, i32 %c, half addrspace(1)* %a)
  ret void
}

declare spir_func void @_Z12vstore_half2Dv2_fjPU3AS1Dh(<2 x float>, i32, half addrspace(1)*)


; CHECK: [[half2:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> %b)
; CHECK: [[a_cast_i32:%[^ ]+]] = bitcast half addrspace(1)* %a to i32 addrspace(1)*
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, i32 addrspace(1)* [[a_cast_i32]], i32 %c
; CHECK: store i32 [[half2]], i32 addrspace(1)* [[gep]], align 4
