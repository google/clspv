; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: call spir_func
define void @foo(<4 x float> addrspace(1)* %a, <4 x float> addrspace(1)* %b) {
entry:
  %ld_b = load <4 x float>, <4 x float> addrspace(1)* %b
  %cast = bitcast <4 x float> addrspace(1)* %a to half addrspace(1)*
  ; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %ld_b, <4 x float> undef, <2 x i32> <i32 0, i32 1>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %ld_b, <4 x float> undef, <2 x i32> <i32 2, i32 3>
  ; CHECK: [[pack0:%[a-zA-Z0-9_.]+]] = call i32 @spirv.pack.v2f16(<2 x float> [[shuffle0]])
  ; CHECK: [[pack1:%[a-zA-Z0-9_.]+]] = call i32 @spirv.pack.v2f16(<2 x float> [[shuffle1]])
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> undef, i32 [[pack0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[pack1]], i32 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(1)* %cast to <2 x i32> addrspace(1)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(1)* [[cast]], i32 0
  ; CHECK: store <2 x i32> [[in1]], <2 x i32> addrspace(1)* [[gep]]
  call spir_func void @_Z12vstore_half4Dv4_fjPU3AS1Dh(<4 x float> %ld_b, i32 0, half addrspace(1)* %cast)
  ret void
}

declare spir_func void @_Z12vstore_half4Dv4_fjPU3AS1Dh(<4 x float>, i32, half addrspace(1)*)
