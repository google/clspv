; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x i32> addrspace(1)* %dst, <8 x i32> addrspace(1)* %src, <8 x i32> addrspace(1)* %min, <8 x i32> addrspace(1)* %max) {
entry:
  %0 = load <8 x i32>, <8 x i32> addrspace(1)* %src, align 32
  %1 = load <8 x i32>, <8 x i32> addrspace(1)* %min, align 32
  %2 = load <8 x i32>, <8 x i32> addrspace(1)* %max, align 32
  %call = call spir_func <8 x i32> @_Z5clampDv8_iS_S_(<8 x i32> %0, <8 x i32> %1, <8 x i32> %2)
  store <8 x i32> %call, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z5clampDv8_iS_S_(<8 x i32>, <8 x i32>, <8 x i32>)

; CHECK-LABEL: @test
; CHECK-NOT: call spir_func <8 x i32> @_Z5clampDv8_iS_S_
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK: {{.*}} = call spir_func i32 @_Z5clampiii(i32 {{.*}}, i32 {{.*}}, i32 {{.*}})
; CHECK-NOT: call spir_func <8 x i32> @_Z5clampDv8_iS_S_
