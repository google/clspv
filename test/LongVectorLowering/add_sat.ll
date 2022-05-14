
; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics,long-vector-lowering,instcombine %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <8 x i8> @add_sat_char8(<8 x i8> %a, <8 x i8> %b) {
entry:
 %call = call <8 x i8> @_Z7add_satDv8_cS_(<8 x i8> %a, <8 x i8> %b)
 ret <8 x i8> %call
}

declare <8 x i8> @_Z7add_satDv8_cS_(<8 x i8>, <8 x i8>)

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

; CHECK: [[sext_a0:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a0]] to i16
; CHECK: [[sext_a1:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a1]] to i16
; CHECK: [[sext_a2:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a2]] to i16
; CHECK: [[sext_a3:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a3]] to i16
; CHECK: [[sext_a4:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a4]] to i16
; CHECK: [[sext_a5:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a5]] to i16
; CHECK: [[sext_a6:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a6]] to i16
; CHECK: [[sext_a7:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a7]] to i16

; CHECK: [[sext_b0:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b0]] to i16
; CHECK: [[sext_b1:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b1]] to i16
; CHECK: [[sext_b2:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b2]] to i16
; CHECK: [[sext_b3:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b3]] to i16
; CHECK: [[sext_b4:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b4]] to i16
; CHECK: [[sext_b5:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b5]] to i16
; CHECK: [[sext_b6:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b6]] to i16
; CHECK: [[sext_b7:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b7]] to i16

; CHECK: [[add0:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a0]], [[sext_b0]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a1]], [[sext_b1]]
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a2]], [[sext_b2]]
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a3]], [[sext_b3]]
; CHECK: [[add4:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a4]], [[sext_b4]]
; CHECK: [[add5:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a5]], [[sext_b5]]
; CHECK: [[add6:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a6]], [[sext_b6]]
; CHECK: [[add7:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a7]], [[sext_b7]]

; CHECK: [[clamp0:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add0]], i16 -128, i16 127)
; CHECK: [[clamp1:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add1]], i16 -128, i16 127)
; CHECK: [[clamp2:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add2]], i16 -128, i16 127)
; CHECK: [[clamp3:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add3]], i16 -128, i16 127)
; CHECK: [[clamp4:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add4]], i16 -128, i16 127)
; CHECK: [[clamp5:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add5]], i16 -128, i16 127)
; CHECK: [[clamp6:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add6]], i16 -128, i16 127)
; CHECK: [[clamp7:%[a-zA-Z0-9_.]+]] = call i16 @_Z5clampsss(i16 [[add7]], i16 -128, i16 127)

; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp0]] to i8
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp1]] to i8
; CHECK: [[trunc2:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp2]] to i8
; CHECK: [[trunc3:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp3]] to i8
; CHECK: [[trunc4:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp4]] to i8
; CHECK: [[trunc5:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp5]] to i8
; CHECK: [[trunc6:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp6]] to i8
; CHECK: [[trunc7:%[a-zA-Z0-9_.]+]] = trunc i16 [[clamp7]] to i8

; CHECK:  [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] undef, i8 [[trunc0]], 0
; CHECK:  [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in0]], i8 [[trunc1]], 1
; CHECK:  [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in1]], i8 [[trunc2]], 2
; CHECK:  [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in2]], i8 [[trunc3]], 3
; CHECK:  [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in3]], i8 [[trunc4]], 4
; CHECK:  [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in4]], i8 [[trunc5]], 5
; CHECK:  [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in5]], i8 [[trunc6]], 6
; CHECK:  [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in6]], i8 [[trunc7]], 7

; CHECK: ret [8 x i8] [[in7]]
