; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define half @sincos_half(half %x, half addrspace(3)* %y) {
entry:
  %call = call spir_func half @_Z6sincosfPU3AS3f(half %x, half addrspace(3)* %y)
  ret half %call
}

declare spir_func half @_Z6sincosfPU3AS3f(half, half addrspace(3)*)

; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call half @llvm.sin.f16(half %x)
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call half @llvm.cos.f16(half %x)
; CHECK: store half [[cos]], half addrspace(3)* %y, align 2
; CHECK: ret half [[sin]]

