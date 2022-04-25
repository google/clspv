; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i32> @isnormal_float2(<2 x float> %x) {
entry:
  %call = call spir_func <2 x i32> @_Z8isnormalDv2_f(<2 x float> %x)
  ret <2 x i32> %call
}

declare spir_func <2 x i32> @_Z8isnormalDv2_f(<2 x float>)

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x float> %x to <2 x i32>
; CHECK: [[abs:%[a-zA-Z0-9_.]+]] = and <2 x i32> [[cast]], <i32 2147483647, i32 2147483647>
; CHECK: [[lt:%[a-zA-Z0-9_.]+]] = icmp ult <2 x i32> [[abs]], <i32 2139095040, i32 2139095040>
; CHECK: [[ge:%[a-zA-Z0-9_.]+]] = icmp uge <2 x i32> [[abs]], <i32 8388608, i32 8388608>
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and <2 x i1> [[lt]], [[ge]]
; CHECK: [[zext:%[a-zA-Z0-9_]+]] = sext <2 x i1> [[and]] to <2 x i32>
; CHECK: ret <2 x i32> [[zext]]

