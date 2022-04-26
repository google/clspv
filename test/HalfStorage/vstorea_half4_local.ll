; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: call spir_func
define void @foo(<2 x i32> addrspace(3)* %a, <4 x float> %b, i32 %n) {
entry:
  %cast = bitcast <2 x i32> addrspace(3)* %a to half addrspace(3)*
  %add.ptr = getelementptr inbounds half, half addrspace(3)* %cast, i32 4
  ; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 0, i32 1>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 2, i32 3>
  ; CHECK: [[pack0:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle0]])
  ; CHECK: [[pack1:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle1]])
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> undef, i32 [[pack0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[pack1]], i32 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(3)* %add.ptr to <2 x i32> addrspace(3)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(3)* [[cast]], i32 %n
  ; CHECK: store <2 x i32> [[in1]], <2 x i32> addrspace(3)* [[gep]]
  call spir_func void @_Z13vstorea_half4Dv4_fjPU3AS3Dh(<4 x float> %b, i32 %n, half addrspace(3)* %add.ptr)

  %add = add i32 %n, 1
  %add.ptr1 = getelementptr inbounds half, half addrspace(3)* %cast, i32 8
  ; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 0, i32 1>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 2, i32 3>
  ; CHECK: [[pack0:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle0]])
  ; CHECK: [[pack1:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle1]])
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> undef, i32 [[pack0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[pack1]], i32 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(3)* %add.ptr1 to <2 x i32> addrspace(3)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(3)* [[cast]], i32 %add
  ; CHECK: store <2 x i32> [[in1]], <2 x i32> addrspace(3)* [[gep]]
  call spir_func void @_Z17vstorea_half4_rteDv4_fjPU3AS3Dh(<4 x float> %b, i32 %add, half addrspace(3)* %add.ptr1)

  %add2 = add i32 %add, 1
  %add.ptr2 = getelementptr inbounds half, half addrspace(3)* %cast, i32 12
  ; CHECK: [[shuffle0:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 0, i32 1>
  ; CHECK: [[shuffle1:%[a-zA-Z0-9_.]+]] = shufflevector <4 x float> %b, <4 x float> undef, <2 x i32> <i32 2, i32 3>
  ; CHECK: [[pack0:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle0]])
  ; CHECK: [[pack1:%[a-zA-Z0-9_.]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[shuffle1]])
  ; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> undef, i32 [[pack0]], i32 0
  ; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[pack1]], i32 1
  ; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast half addrspace(3)* %add.ptr2 to <2 x i32> addrspace(3)*
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <2 x i32>, <2 x i32> addrspace(3)* [[cast]], i32 %add2
  ; CHECK: store <2 x i32> [[in1]], <2 x i32> addrspace(3)* [[gep]]
  call spir_func void @_Z17vstorea_half4_rteDv4_fjPU3AS3Dh(<4 x float> %b, i32 %add2, half addrspace(3)* %add.ptr2)
  ret void
}

declare spir_func void @_Z13vstorea_half4Dv4_fjPU3AS3Dh(<4 x float>, i32, half addrspace(3)*)
declare spir_func void @_Z17vstorea_half4_rteDv4_fjPU3AS3Dh(<4 x float>, i32, half addrspace(3)*)
declare spir_func void @_Z17vstorea_half4_rtzDv4_fjPU3AS3Dh(<4 x float>, i32, half addrspace(3)*)


