; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i64> @isnormal_double2(<2 x double> %x) {
entry:
  %call = call spir_func <2 x i64> @_Z8isnormalDv2_d(<2 x double> %x)
  ret <2 x i64> %call
}

declare spir_func <2 x i64> @_Z8isnormalDv2_d(<2 x double>)

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x double> %x to <2 x i64>
; CHECK: [[abs:%[a-zA-Z0-9_.]+]] = and <2 x i64> [[cast]], <i64 9223372036854775807, i64 9223372036854775807>
; CHECK: [[lt:%[a-zA-Z0-9_.]+]] = icmp ult <2 x i64> [[abs]], <i64 9218868437227405312, i64 9218868437227405312>
; CHECK: [[ge:%[a-zA-Z0-9_.]+]] = icmp uge <2 x i64> [[abs]], <i64 4503599627370496, i64 4503599627370496>
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and <2 x i1> [[lt]], [[ge]]
; CHECK: [[zext:%[a-zA-Z0-9_]+]] = sext <2 x i1> [[and]] to <2 x i64>
; CHECK: ret <2 x i64> [[zext]]
