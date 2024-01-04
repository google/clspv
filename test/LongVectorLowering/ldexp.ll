; RUN: clspv-opt --passes=long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %x, ptr addrspace(1) %k) {
entry:
  %0 = load <8 x float>, ptr addrspace(1) %x, align 32
  %1 = load <8 x i32>, ptr addrspace(1) %k, align 32
  %call = call spir_func <8 x float> @_Z5ldexpDv8_fDv8_i(<8 x float> %0, <8 x i32> %1)
  store <8 x float> %call, ptr addrspace(1) %x, align 32
  ret void
}

declare spir_func <8 x float> @_Z5ldexpDv8_fDv8_i(<8 x float>, <8 x i32>)

; CHECK-LABEL: @test
; CHECK-NOT: call spir_func <8 x float> @_Z5ldexpDv8_fDv8_i
; CHECK-COUNT-8: {{.*}} = call spir_func float @_Z5ldexpfi(float {{.*}}, i32 {{.*}})
; CHECK-NOT: call spir_func <8 x float> @_Z5ldexpDv8_fDv8_i

define spir_kernel void @test2(ptr addrspace(1) %x, ptr addrspace(1) %k) {
entry:
  %0 = load <16 x float>, ptr addrspace(1) %x, align 32
  %1 = load i32, ptr addrspace(1) %k, align 32
  %call = call spir_func <16 x float> @_Z5ldexpDv16_fi(<16 x float> %0, i32 %1)
  store <16 x float> %call, ptr addrspace(1) %x, align 32
  ret void
}

declare spir_func <16 x float> @_Z5ldexpDv16_fi(<16 x float>, i32)

; CHECK-LABEL: @test2
; CHECK-NOT: call spir_func <16 x float> @_Z5ldexpDv8_fi
; CHECK-COUNT-16: {{.*}} = call spir_func float @_Z5ldexpfi(float {{.*}}, i32 {{.*}})
; CHECK-NOT: call spir_func <16 x float> @_Z5ldexpDv8_fi
