; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s --implicit-check-not=_Z7degreesd --implicit-check-not=_Z7degreesDv4_d --implicit-check-not=_Z7radiansd --implicit-check-not=_Z7radiansDv4_d < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-unknown"

declare spir_func double @_Z7degreesd(double)
declare spir_func <4 x double> @_Z7degreesDv4_d(<4 x double>)
declare spir_func float @_Z7degreesf(float)
declare spir_func half @_Z7degreesDh(half)
declare spir_func double @_Z7radiansd(double)
declare spir_func <4 x double> @_Z7radiansDv4_d(<4 x double>)

; CHECK-LABEL: @deg_double
; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = fmul double %x, f0x404CA5DC1A63C1F8
; CHECK-NEXT: ret double [[mul]]
define double @deg_double(double %x) {
  %r = call spir_func double @_Z7degreesd(double %x)
  ret double %r
}

; CHECK-LABEL: @deg_double4
; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = fmul <4 x double> %x, splat (double f0x404CA5DC1A63C1F8)
; CHECK-NEXT: ret <4 x double> [[mul]]
define <4 x double> @deg_double4(<4 x double> %x) {
  %r = call spir_func <4 x double> @_Z7degreesDv4_d(<4 x double> %x)
  ret <4 x double> %r
}

; Non-double types remain GLSL.std.450 candidates.
; CHECK-LABEL: @deg_float
; CHECK-NEXT: %r = call spir_func float @_Z7degreesf(float %x)
define float @deg_float(float %x) {
  %r = call spir_func float @_Z7degreesf(float %x)
  ret float %r
}

; CHECK-LABEL: @deg_half
; CHECK-NEXT: %r = call spir_func half @_Z7degreesDh(half %x)
define half @deg_half(half %x) {
  %r = call spir_func half @_Z7degreesDh(half %x)
  ret half %r
}

; CHECK-LABEL: @rad_double
; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = fmul double %x, f0x3F91DF46A2529D39
; CHECK-NEXT: ret double [[mul]]
define double @rad_double(double %x) {
  %r = call spir_func double @_Z7radiansd(double %x)
  ret double %r
}

; CHECK-LABEL: @rad_double4
; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = fmul <4 x double> %x, splat (double f0x3F91DF46A2529D39)
; CHECK-NEXT: ret <4 x double> [[mul]]
define <4 x double> @rad_double4(<4 x double> %x) {
  %r = call spir_func <4 x double> @_Z7radiansDv4_d(<4 x double> %x)
  ret <4 x double> %r
}
