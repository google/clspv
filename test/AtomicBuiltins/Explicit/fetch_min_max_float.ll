; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s --check-prefix=IR --implicit-check-not=spirv.op.236 --implicit-check-not=spirv.op.238 < %t.ll
; RUN: clspv -x=ir %s -o %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s --check-prefix=SPV --implicit-check-not=OpAtomicSMin --implicit-check-not=OpAtomicSMax < %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

; Floating-point atomic_fetch_min/max must lower to OpAtomicFMinEXT (5614) and
; OpAtomicFMaxEXT (5615), not OpAtomicSMin (236) and OpAtomicSMax (238).

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; IR-LABEL: define spir_kernel void @fmin_fmax(
; IR: call float @_Z8spirv.op.5614.{{.*}}(i32 5614, ptr addrspace(1) %ptr, i32 1, i32 0, float %v)
; IR: call float @_Z8spirv.op.5615.{{.*}}(i32 5615, ptr addrspace(1) %ptr, i32 1, i32 0, float %v)
; IR: call float @_Z8spirv.op.5614.{{.*}}(i32 5614, ptr addrspace(3) @local, i32 2, i32 0, float %v)
; IR: call float @_Z8spirv.op.5615.{{.*}}(i32 5615, ptr addrspace(3) @local, i32 2, i32 0, float %v)

; SPV: OpCapability AtomicFloat32MinMaxEXT
; SPV: OpExtension "SPV_EXT_shader_atomic_float_min_max"
; SPV: OpAtomicFMinEXT %float
; SPV: OpAtomicFMaxEXT %float
; SPV: OpAtomicFMinEXT %float
; SPV: OpAtomicFMaxEXT %float

@local = internal addrspace(3) global float undef, align 4

define spir_kernel void @fmin_fmax(ptr addrspace(1) %ptr, ptr addrspace(1) %out, float %v) {
entry:
  %min_g = call spir_func float @_Z25atomic_fetch_min_explicitPU3AS1Vffii(ptr addrspace(1) %ptr, float %v, i32 0, i32 2)
  %max_g = call spir_func float @_Z25atomic_fetch_max_explicitPU3AS1Vffii(ptr addrspace(1) %ptr, float %v, i32 0, i32 2)
  %min_l = call spir_func float @_Z25atomic_fetch_min_explicitPU3AS3Vffii(ptr addrspace(3) @local, float %v, i32 0, i32 1)
  %max_l = call spir_func float @_Z25atomic_fetch_max_explicitPU3AS3Vffii(ptr addrspace(3) @local, float %v, i32 0, i32 1)
  %a = fadd float %min_g, %max_g
  %b = fadd float %min_l, %max_l
  %c = fadd float %a, %b
  store float %c, ptr addrspace(1) %out, align 4
  ret void
}

declare spir_func float @_Z25atomic_fetch_min_explicitPU3AS1Vffii(ptr addrspace(1), float, i32, i32)
declare spir_func float @_Z25atomic_fetch_max_explicitPU3AS1Vffii(ptr addrspace(1), float, i32, i32)
declare spir_func float @_Z25atomic_fetch_min_explicitPU3AS3Vffii(ptr addrspace(3), float, i32, i32)
declare spir_func float @_Z25atomic_fetch_max_explicitPU3AS3Vffii(ptr addrspace(3), float, i32, i32)
