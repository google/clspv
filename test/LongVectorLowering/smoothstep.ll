; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x float> addrspace(1)* %dst, <8 x float> addrspace(1)* %edge0, <8 x float> addrspace(1)* %edge1, <8 x float> addrspace(1)* %src) {
entry:
  %0 = load <8 x float>, <8 x float> addrspace(1)* %edge0, align 32
  %1 = load <8 x float>, <8 x float> addrspace(1)* %edge1, align 32
  %2 = load <8 x float>, <8 x float> addrspace(1)* %src, align 32
  %call = call spir_func <8 x float> @_Z10smoothstepDv8_fS_S_(<8 x float> %0, <8 x float> %1, <8 x float> %2)
  store <8 x float> %call, <8 x float> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x float> @_Z10smoothstepDv8_fS_S_(<8 x float>, <8 x float>, <8 x float>)

; CHECK-LABEL: @test
; CHECK-NOT: call spir_func <8 x float> @_Z10smoothstepDv8_fS_S_
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK: {{.*}} = call spir_func float @_Z10smoothstepfff(float {{.*}}, float {{.*}}, float {{.*}})
; CHECK-NOT: call spir_func <8 x float> @_Z10smoothstepDv8_fS_S_
