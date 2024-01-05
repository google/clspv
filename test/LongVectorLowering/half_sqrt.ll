; RUN: clspv-opt --passes=long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %x) {
entry:
  %0 = load <8 x float>, ptr addrspace(1) %x, align 32
  %call = call spir_func <8 x float> @_Z9half_sqrtDv8_f(<8 x float> %0)
  store <8 x float> %call, ptr addrspace(1) %x, align 32
  ret void
}

declare spir_func <8 x float> @_Z9half_sqrtDv8_f(<8 x float>)

; CHECK-LABEL: @test
; CHECK-NOT: call spir_func <8 x float> @_Z9half_sqrtDv8_f
; CHECK-COUNT-8: {{.*}} = call spir_func float @_Z9half_sqrtf(float {{.*}})
; CHECK-NOT: call spir_func <8 x float> @_Z9half_sqrtDv8_f
