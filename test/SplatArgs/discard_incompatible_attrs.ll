; RUN: clspv-opt --passes=splat-arg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @testSplatMax(<2 x i8> addrspace(1)* nocapture readonly align 2 %in) {
entry:
  %0 = load <2 x i8>, <2 x i8> addrspace(1)* %in, align 2
  ; CHECK: %call = tail call spir_func <2 x i8> @_Z3maxDv2_cS_(<2 x i8> %0, <2 x i8> zeroinitializer)
  ; CHECK: %call2 = tail call spir_func <2 x i8> @_Z3maxDv2_hS_(<2 x i8> %0, <2 x i8> zeroinitializer)
  %call = tail call spir_func <2 x i8> @_Z3maxDv2_cc(<2 x i8> %0, i8 signext 0)
  %call2 = tail call spir_func <2 x i8> @_Z3maxDv2_hh(<2 x i8> %0, i8 zeroext 0)
  ret void
}

; CHECK: declare spir_func <2 x i8> @_Z3maxDv2_cS_(<2 x i8>, <2 x i8>)
declare spir_func <2 x i8> @_Z3maxDv2_cc(<2 x i8> %0, i8 signext %1)

; CHECK: declare spir_func <2 x i8> @_Z3maxDv2_hS_(<2 x i8>, <2 x i8>)
declare spir_func <2 x i8> @_Z3maxDv2_hh(<2 x i8> %0, i8 zeroext %1)
