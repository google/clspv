; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: call spir_func
define void @foo(<4 x float> addrspace(1)* %a, <4 x float> addrspace(1)* %b) {
entry:
  %cast = bitcast <4 x float> addrspace(1)* %b to half addrspace(1)*
  ;CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(1)* %cast to i32 addrspace(1)*
  ;CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i32, i32 addrspace(1)* [[cast]], i32 0
  ;CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* [[gep]]
  ;CHECK: [[unpack:%[a-zA-Z0-9_.]+]] = call <2 x float> @spirv.unpack.v2f16(i32 [[ld]])
  %call = call spir_func <2 x float> @_Z11vload_half2jPU3AS1KDh(i32 0, half addrspace(1)* %cast) #2
  ret void
}

declare <2 x float> @_Z11vload_half2jPU3AS1KDh(i32, half addrspace(1)*)

