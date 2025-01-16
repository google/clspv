; RUN: clspv-opt --passes=long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-COUNT-8: call spir_func float @_Z3madfff(

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) align 32 %a) {
entry:
  %arrayidx = getelementptr inbounds <8 x float>, ptr addrspace(1) %a, i32 1
  %0 = load <8 x float>, ptr addrspace(1) %arrayidx, align 32
  %arrayidx1 = getelementptr inbounds <8 x float>, ptr addrspace(1) %a, i32 2
  %1 = load <8 x float>, ptr addrspace(1) %arrayidx1, align 32
  %arrayidx2 = getelementptr inbounds <8 x float>, ptr addrspace(1) %a, i32 3
  %2 = load <8 x float>, ptr addrspace(1) %arrayidx2, align 32
  %call = call spir_func <8 x float> @_Z3madDv8_fS_S_(<8 x float> %0, <8 x float> %1, <8 x float> %2)
  %arrayidx3 = getelementptr inbounds <8 x float>, ptr addrspace(1) %a, i32 0
  store <8 x float> %call, ptr addrspace(1) %arrayidx3, align 32
  ret void
}

declare spir_func <8 x float> @_Z3madDv8_fS_S_(<8 x float>, <8 x float>, <8 x float>)

