; RUN: clspv-opt %s -o %t -ReplacePointerBitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 %n, 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(3)* %b, i32 [[shr]]
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load <4 x float>, <4 x float> addrspace(3)* [[gep]]
; CHECK: [[n_and:%[a-zA-Z0-9_.]+]] = and i32 %n, 1
; CHECK: [[n_shl:%[a-zA-Z0-9_.]+]] = shl i32 [[n_and]], 1
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> [[ld]], i32 [[n_shl]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> undef, float [[ex0]], i32 0
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[n_shl]], 1
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <4 x float> [[ld]], i32 [[add]]
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> [[in0]], float [[ex1]], i32 1
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = bitcast <2 x float> [[in1]] to <2 x i32>
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i32 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i32 1
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[ex0]])
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[ex1]])
define void @foo(<4 x float> addrspace(1)* %a, <4 x float> addrspace(3)* %b, i32 %n) {
entry:
  %cast = bitcast <4 x float> addrspace(3)* %b to <2 x i32> addrspace(3)*
  %gep = getelementptr <2 x i32>, <2 x i32> addrspace(3)* %cast, i32 %n
  %ld = load <2 x i32>, <2 x i32> addrspace(3)* %gep
  %ex0 = extractelement <2 x i32> %ld, i32 0
  %ex1 = extractelement <2 x i32> %ld, i32 1
  %unpack0 = call <2 x float> @spirv.unpack.v2f16(i32 %ex0)
  %unpack1 = call <2 x float> @spirv.unpack.v2f16(i32 %ex1)
  %shuffle = shufflevector <2 x float> %unpack0, <2 x float> %unpack1, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret void
}

declare <2 x float> @spirv.unpack.v2f16(i32)

