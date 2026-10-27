; RUN: clspv-opt --passes=fixup-builtins %s -o %t.ll
; RUN: FileCheck %s --check-prefix=FLUSH < %t.ll
; RUN: clspv-opt --passes=fixup-builtins -denorm-preserve=32 %s -o %t.preserve.ll
; RUN: FileCheck %s --check-prefix=PRESERVE < %t.preserve.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

declare float @llvm.canonicalize.f32(float)
declare <2 x float> @llvm.canonicalize.v2f32(<2 x float>)

; FLUSH-LABEL: @test_scalar
; FLUSH-NOT: call float @llvm.canonicalize.f32
; FLUSH: store float 1.000000e+00, ptr addrspace(1) %out0
; FLUSH: store float 0.000000e+00, ptr addrspace(1) %out1
; FLUSH: store float -0.000000e+00, ptr addrspace(1) %out2
; FLUSH: store float +nan(0x200000), ptr addrspace(1) %out3

; PRESERVE-LABEL: @test_scalar
; PRESERVE-NOT: call float @llvm.canonicalize.f32
; PRESERVE: store float 1.000000e+00, ptr addrspace(1) %out0
; PRESERVE: store float 1.401300e-45, ptr addrspace(1) %out1
; PRESERVE: store float -1.401300e-45, ptr addrspace(1) %out2
; PRESERVE: store float +nan(0x200000), ptr addrspace(1) %out3
define spir_kernel void @test_scalar(ptr addrspace(1) %out0, ptr addrspace(1) %out1, ptr addrspace(1) %out2, ptr addrspace(1) %out3) {
entry:
  %c0 = call float @llvm.canonicalize.f32(float 1.000000e+00)
  store float %c0, ptr addrspace(1) %out0, align 4
  %c1 = call float @llvm.canonicalize.f32(float f0x00000001)
  store float %c1, ptr addrspace(1) %out1, align 4
  %c2 = call float @llvm.canonicalize.f32(float f0x80000001)
  store float %c2, ptr addrspace(1) %out2, align 4
  %c3 = call float @llvm.canonicalize.f32(float +snan(0x200000))
  store float %c3, ptr addrspace(1) %out3, align 4
  ret void
}

; FLUSH-LABEL: @test_vector
; FLUSH-NOT: call <2 x float> @llvm.canonicalize.v2f32
; FLUSH: store <2 x float> <float 1.000000e+00, float 0.000000e+00>, ptr addrspace(1) %out

; PRESERVE-LABEL: @test_vector
; PRESERVE-NOT: call <2 x float> @llvm.canonicalize.v2f32
; PRESERVE: store <2 x float> <float 1.000000e+00, float 1.401300e-45>, ptr addrspace(1) %out
define spir_kernel void @test_vector(ptr addrspace(1) %out) {
entry:
  %c = call <2 x float> @llvm.canonicalize.v2f32(<2 x float> <float 1.000000e+00, float f0x00000001>)
  store <2 x float> %c, ptr addrspace(1) %out, align 8
  ret void
}
