; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define float @sincos_float(float %x, ptr addrspace(1) %y) {
entry:
  %call = call spir_func float @_Z6sincosfPU3AS1f(float %x, ptr addrspace(1) %y)
  ret float %call
}

declare spir_func float @_Z6sincosfPU3AS1f(float, ptr addrspace(1))

; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call float @llvm.sin.f32(float %x)
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call float @llvm.cos.f32(float %x)
; CHECK: store float [[cos]], ptr addrspace(1) %y, align 4
; CHECK: ret float [[sin]]
