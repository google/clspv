; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i16> @isnormal_half2(<2 x half> %x) {
entry:
  %call = call spir_func <2 x i16> @_Z8isnormalDv2_Dh(<2 x half> %x)
  ret <2 x i16> %call
}

declare spir_func <2 x i16> @_Z8isnormalDv2_Dh(<2 x half>)

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x half> %x to <2 x i16>
; CHECK: [[abs:%[a-zA-Z0-9_.]+]] = and <2 x i16> [[cast]], <i16 32767, i16 32767>
; CHECK: [[lt:%[a-zA-Z0-9_.]+]] = icmp ult <2 x i16> [[abs]], <i16 31744, i16 31744>
; CHECK: [[ge:%[a-zA-Z0-9_.]+]] = icmp uge <2 x i16> [[abs]], <i16 1024, i16 1024>
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and <2 x i1> [[lt]], [[ge]]
; CHECK: [[zext:%[a-zA-Z0-9_]+]] = sext <2 x i1> [[and]] to <2 x i16>
; CHECK: ret <2 x i16> [[zext]]

