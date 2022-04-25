
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[conv:%[a-zA-Z0-9_.]+]] = sitofp <2 x i16> %x to <2 x half>
; CHECK: ret <2 x half> [[conv]]

define <2 x half>@foo(<2 x i16> %x) {
entry:
  %call = call <2 x half> @_Z13convert_half2Dv2_s(<2 x i16> %x)
  ret <2 x half> %call
}

declare <2 x half> @_Z13convert_half2Dv2_s(<2 x i16>)
