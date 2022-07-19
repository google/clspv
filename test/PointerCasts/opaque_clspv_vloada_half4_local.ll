; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %n, 1
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[shl]], 2
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shl]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(3) %b, i32 [[shr]], i32 [[and]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(3) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[and]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(3) %b, i32 [[shr]], i32 [[add]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(3) [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> undef, float [[ld0]], i32 0
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> [[in0]], float [[ld1]], i32 1
; CHECK: [[cast:%[a-zA-Z0-9_]+]] = bitcast <2 x float> [[in1]] to <2 x i32>
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i32 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x i32> [[cast]], i32 1
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[ex0]])
; CHECK: call <2 x float> @spirv.unpack.v2f16(i32 [[ex1]])
define void @foo(ptr addrspace(1) %a, i32 %n) {
entry:
  %res = call ptr addrspace(3) @clspv.local.3(i32 3, [0 x <4 x float>] zeroinitializer)
  %b = getelementptr [0 x <4 x float>], ptr addrspace(3) %res, i32 0, i32 0
  %gep = getelementptr <2 x i32>, ptr addrspace(3) %b, i32 %n
  %ld = load <2 x i32>, ptr addrspace(3) %gep
  %ex0 = extractelement <2 x i32> %ld, i32 0
  %ex1 = extractelement <2 x i32> %ld, i32 1
  %unpack0 = call <2 x float> @spirv.unpack.v2f16(i32 %ex0)
  %unpack1 = call <2 x float> @spirv.unpack.v2f16(i32 %ex1)
  %shuffle = shufflevector <2 x float> %unpack0, <2 x float> %unpack1, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret void
}

declare <2 x float> @spirv.unpack.v2f16(i32)
declare ptr addrspace(3) @clspv.local.3(i32, [0 x <4 x float>])

