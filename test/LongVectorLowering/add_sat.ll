
; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics,long-vector-lowering,instcombine %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define <8 x i8> @add_sat_char8(<8 x i8> %a, <8 x i8> %b) {
entry:
 %call = call <8 x i8> @_Z7add_satDv8_cS_(<8 x i8> %a, <8 x i8> %b)
 ret <8 x i8> %call
}

declare <8 x i8> @_Z7add_satDv8_cS_(<8 x i8>, <8 x i8>)

; CHECK-DAG: [[ex_a0:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 0
; CHECK-DAG: [[ex_a1:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 1
; CHECK-DAG: [[ex_a2:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 2
; CHECK-DAG: [[ex_a3:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 3
; CHECK-DAG: [[ex_a4:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 4
; CHECK-DAG: [[ex_a5:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 5
; CHECK-DAG: [[ex_a6:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 6
; CHECK-DAG: [[ex_a7:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %a, 7

; CHECK-DAG: [[ex_b0:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 0
; CHECK-DAG: [[ex_b1:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 1
; CHECK-DAG: [[ex_b2:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 2
; CHECK-DAG: [[ex_b3:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 3
; CHECK-DAG: [[ex_b4:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 4
; CHECK-DAG: [[ex_b5:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 5
; CHECK-DAG: [[ex_b6:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 6
; CHECK-DAG: [[ex_b7:%[a-zA-Z0-9_.]+]] = extractvalue [8 x i8] %b, 7

; CHECK-DAG: [[sext_a0:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a0]] to i16
; CHECK-DAG: [[sext_a1:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a1]] to i16
; CHECK-DAG: [[sext_a2:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a2]] to i16
; CHECK-DAG: [[sext_a3:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a3]] to i16
; CHECK-DAG: [[sext_a4:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a4]] to i16
; CHECK-DAG: [[sext_a5:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a5]] to i16
; CHECK-DAG: [[sext_a6:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a6]] to i16
; CHECK-DAG: [[sext_a7:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_a7]] to i16

; CHECK-DAG: [[sext_b0:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b0]] to i16
; CHECK-DAG: [[sext_b1:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b1]] to i16
; CHECK-DAG: [[sext_b2:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b2]] to i16
; CHECK-DAG: [[sext_b3:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b3]] to i16
; CHECK-DAG: [[sext_b4:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b4]] to i16
; CHECK-DAG: [[sext_b5:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b5]] to i16
; CHECK-DAG: [[sext_b6:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b6]] to i16
; CHECK-DAG: [[sext_b7:%[a-zA-Z0-9_.]+]] = sext i8 [[ex_b7]] to i16

; CHECK: [[add0:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a0]], [[sext_b0]]
; CHECK: [[add1:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a1]], [[sext_b1]]
; CHECK: [[add2:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a2]], [[sext_b2]]
; CHECK: [[add3:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a3]], [[sext_b3]]
; CHECK: [[add4:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a4]], [[sext_b4]]
; CHECK: [[add5:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a5]], [[sext_b5]]
; CHECK: [[add6:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a6]], [[sext_b6]]
; CHECK: [[add7:%[a-zA-Z0-9_.]+]] = add nuw nsw i16 [[sext_a7]], [[sext_b7]]

; CHECK: [[clamp_lo:%[a-zA-Z0-9_.]+]] = call <4 x i16> @_Z5clampDv4_sDv4_sDv4_s(<4 x i16> {{.*}}, <4 x i16> splat (i16 -128), <4 x i16> splat (i16 127))
; CHECK: [[clamp_hi:%[a-zA-Z0-9_.]+]] = call <4 x i16> @_Z5clampDv4_sDv4_sDv4_s(<4 x i16> {{.*}}, <4 x i16> splat (i16 -128), <4 x i16> splat (i16 127))

; CHECK-DAG: [[bitcast0:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_lo]] to <8 x i8>
; CHECK-DAG: [[bitcast1:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_lo]] to <8 x i8>
; CHECK-DAG: [[bitcast2:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_lo]] to <8 x i8>
; CHECK-DAG: [[bitcast3:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_lo]] to <8 x i8>
; CHECK-DAG: [[bitcast4:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_hi]] to <8 x i8>
; CHECK-DAG: [[bitcast5:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_hi]] to <8 x i8>
; CHECK-DAG: [[bitcast6:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_hi]] to <8 x i8>
; CHECK-DAG: [[bitcast7:%[a-zA-Z0-9_.]+]] = bitcast <4 x i16> [[clamp_hi]] to <8 x i8>

; CHECK-DAG: [[clamp0:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast0]], i64 0
; CHECK-DAG: [[clamp1:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast1]], i64 2
; CHECK-DAG: [[clamp2:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast2]], i64 4
; CHECK-DAG: [[clamp3:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast3]], i64 6
; CHECK-DAG: [[clamp4:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast4]], i64 0
; CHECK-DAG: [[clamp5:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast5]], i64 2
; CHECK-DAG: [[clamp6:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast6]], i64 4
; CHECK-DAG: [[clamp7:%[a-zA-Z0-9_.]+]] = extractelement <8 x i8> [[bitcast7]], i64 6

; CHECK:  [[in0:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] poison, i8 [[clamp0]], 0
; CHECK:  [[in1:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in0]], i8 [[clamp1]], 1
; CHECK:  [[in2:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in1]], i8 [[clamp2]], 2
; CHECK:  [[in3:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in2]], i8 [[clamp3]], 3
; CHECK:  [[in4:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in3]], i8 [[clamp4]], 4
; CHECK:  [[in5:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in4]], i8 [[clamp5]], 5
; CHECK:  [[in6:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in5]], i8 [[clamp6]], 6
; CHECK:  [[in7:%[a-zA-Z0-9_.]+]] = insertvalue [8 x i8] [[in6]], i8 [[clamp7]], 7

; CHECK: ret [8 x i8] [[in7]]
