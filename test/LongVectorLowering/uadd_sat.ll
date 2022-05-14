
; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics,long-vector-lowering,instcombine %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <8 x i8> @add_sat_char8(<8 x i8> %a, <8 x i8> %b) {
entry:
 %call = call <8 x i8> @_Z7add_satDv8_hS_(<8 x i8> %a, <8 x i8> %b)
 ret <8 x i8> %call
}

declare <8 x i8> @_Z7add_satDv8_hS_(<8 x i8>, <8 x i8>)

; CHECK: [[ex_a0:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 0
; CHECK: [[ex_a1:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 1
; CHECK: [[ex_a2:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 2
; CHECK: [[ex_a3:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 3
; CHECK: [[ex_a4:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 4
; CHECK: [[ex_a5:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 5
; CHECK: [[ex_a6:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 6
; CHECK: [[ex_a7:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 7

; CHECK: [[ex_b0:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 0
; CHECK: [[ex_b1:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 1
; CHECK: [[ex_b2:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 2
; CHECK: [[ex_b3:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 3
; CHECK: [[ex_b4:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 4
; CHECK: [[ex_b5:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 5
; CHECK: [[ex_b6:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 6
; CHECK: [[ex_b7:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 7

; CHECK: [[add0:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a0]], i8 [[ex_b0]])
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a1]], i8 [[ex_b1]])
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a2]], i8 [[ex_b2]])
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a3]], i8 [[ex_b3]])
; CHECK: [[add4:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a4]], i8 [[ex_b4]])
; CHECK: [[add5:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a5]], i8 [[ex_b5]])
; CHECK: [[add6:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a6]], i8 [[ex_b6]])
; CHECK: [[add7:%[a-zA-Z0-9_.]+]] = call %0 @_Z8spirv.op(i32 149, i8 [[ex_a7]], i8 [[ex_b7]])
