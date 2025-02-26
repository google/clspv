; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 32 %a, ptr addrspace(1) align 32 %b) {
entry:
  %a.addr = alloca ptr addrspace(1), align 4
  %b.addr = alloca ptr addrspace(1), align 4
  store ptr addrspace(1) %a, ptr %a.addr, align 4
  store ptr addrspace(1) %b, ptr %b.addr, align 4
  %0 = load ptr addrspace(1), ptr %b.addr, align 4
  %1 = load <8 x float>, ptr addrspace(1) %0, align 32
  %call = call spir_func <8 x float> @_Z10native_expDv8_f(<8 x float> %1) #2
  %2 = load ptr addrspace(1), ptr %a.addr, align 4
  store <8 x float> %call, ptr addrspace(1) %2, align 32
  ret void
}

declare spir_func <8 x float> @_Z10native_expDv8_f(<8 x float>) #1

; CHECK-LABEL: @test
; CHECK-NOT: call spir_func <8 x float> @_Z10native_expDv8_f
; CHECK-COUNT-8: {{.*}} = call spir_func float @_Z10native_expf(float {{.*}})
; CHECK-NOT: call spir_func <8 x float> @_Z10native_expDv8_f
