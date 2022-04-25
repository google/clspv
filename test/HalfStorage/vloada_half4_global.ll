; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: call spir_func
define void @foo(<4 x float> addrspace(1)* %a, <2 x i32> addrspace(1)* %b, i32 %n) {
entry:
  %cast = bitcast <2 x i32> addrspace(1)* %b to half addrspace(1)*
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(1)* %cast to <2 x i32> addrspace(1)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* [[cast]], i32 %n
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <2 x i32>, <2 x i32> addrspace(1)* [[gep]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[ld]], i32 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[ld]], i32 1
  ; CHECK: [[unpack0:%[a-zA-Z0-9_.]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[ex0]])
  ; CHECK: [[unpack1:%[a-zA-Z0-9_.]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[ex1]])
  %call = call spir_func <4 x float> @_Z12vloada_half4jPU3AS1KDh(i32 %n, half addrspace(1)* %cast)

  %add.ptr = getelementptr inbounds half, half addrspace(1)* %cast, i32 2
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(1)* %add.ptr to <2 x i32> addrspace(1)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* [[cast]], i32 0
  ; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <2 x i32>, <2 x i32> addrspace(1)* [[gep]]
  ; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[ld]], i32 0
  ; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[ld]], i32 1
  ; CHECK: [[unpack0:%[a-zA-Z0-9_.]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[ex0]])
  ; CHECK: [[unpack1:%[a-zA-Z0-9_.]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[ex1]])
  %call1 = call spir_func <4 x float> @_Z12vloada_half4jPU3AS1KDh(i32 0, half addrspace(1)* %add.ptr)
  ret void
}

declare <4 x float> @_Z12vloada_half4jPU3AS1KDh(i32, half addrspace(1)*)

